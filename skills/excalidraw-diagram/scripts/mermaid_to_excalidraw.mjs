#!/usr/bin/env node

import fs from "node:fs/promises";
import path from "node:path";

async function loadMermaidParser() {
  try {
    const pkg = await import("@excalidraw/mermaid-to-excalidraw");
    const parser = pkg.parseMermaidToExcalidraw ?? pkg?.default?.parseMermaidToExcalidraw;
    if (typeof parser !== "function") {
      throw new Error("parseMermaidToExcalidraw export not found");
    }
    return parser;
  } catch (error) {
    throw new Error(
      "missing Mermaid converter dependency. Run: cd scripts && npm install",
      { cause: error },
    );
  }
}

function parseArgs(argv) {
  const args = {
    input: null,
    output: null,
    convert: "auto", // auto | always | never
    source: "https://excalidraw.com",
  };

  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    if (!token.startsWith("--") && !args.input) {
      args.input = token;
      continue;
    }
    if (token === "--output" || token === "-o") {
      args.output = argv[i + 1];
      i += 1;
      continue;
    }
    if (token === "--force-convert") {
      args.convert = "always";
      continue;
    }
    if (token === "--no-convert") {
      args.convert = "never";
      continue;
    }
    if (token === "--source") {
      args.source = argv[i + 1];
      i += 1;
      continue;
    }
    if (token === "--help" || token === "-h") {
      args.help = true;
      continue;
    }
    throw new Error(`unknown argument: ${token}`);
  }

  return args;
}

function printHelp() {
  console.log(
    [
      "Convert Mermaid to Excalidraw JSON.",
      "",
      "Usage:",
      "  node mermaid_to_excalidraw.mjs <input.mmd|input.md> [--output file.excalidraw]",
      "                                 [--force-convert|--no-convert]",
      "",
      "Options:",
      "  --output, -o      Output .excalidraw path (default: input basename + .excalidraw)",
      "  --force-convert   Always run convertToExcalidrawElements when available",
      "  --no-convert      Never run convertToExcalidrawElements",
      "  --source          Value for top-level JSON 'source' field",
    ].join("\n"),
  );
}

function defaultOutputPath(inputPath) {
  const resolved = path.resolve(inputPath);
  const parsed = path.parse(resolved);
  return path.join(parsed.dir, `${parsed.name}.excalidraw`);
}

function extractMermaid(content) {
  const blocks = [...content.matchAll(/```mermaid\s*([\s\S]*?)```/gim)];
  if (blocks.length > 0) {
    const first = blocks[0]?.[1] ?? "";
    return first.trim();
  }
  return content.trim();
}

function normalizeParseResult(result) {
  if (result && typeof result === "object") {
    if (Array.isArray(result.elements)) {
      return { elements: result.elements, files: result.files ?? {} };
    }
    if (Array.isArray(result.excalidrawElements)) {
      return { elements: result.excalidrawElements, files: result.files ?? {} };
    }
  }
  throw new Error("unsupported parser output shape from parseMermaidToExcalidraw");
}

function looksLikeSkeleton(elements) {
  if (!Array.isArray(elements) || elements.length === 0) {
    return false;
  }
  let skeletonVotes = 0;
  for (const element of elements) {
    if (!element || typeof element !== "object") {
      continue;
    }
    if (!("seed" in element) || !("version" in element)) {
      skeletonVotes += 1;
    }
  }
  return skeletonVotes > 0;
}

async function maybeConvertElements(elements, mode) {
  if (mode === "never") {
    return { elements, converted: false };
  }

  const shouldAttempt = mode === "always" || looksLikeSkeleton(elements);
  if (!shouldAttempt) {
    return { elements, converted: false };
  }

  try {
    const excalidrawPkg = await import("@excalidraw/excalidraw");
    const convertFn =
      excalidrawPkg.convertToExcalidrawElements ??
      excalidrawPkg?.default?.convertToExcalidrawElements ??
      null;
    if (typeof convertFn !== "function") {
      if (mode === "always") {
        throw new Error("convertToExcalidrawElements not exported by @excalidraw/excalidraw");
      }
      return { elements, converted: false };
    }

    const converted = convertFn(elements);
    if (!Array.isArray(converted) || converted.length === 0) {
      throw new Error("convertToExcalidrawElements returned empty/non-array data");
    }
    return { elements: converted, converted: true };
  } catch (error) {
    if (mode === "always") {
      throw error;
    }
    return { elements, converted: false };
  }
}

async function main() {
  try {
    const args = parseArgs(process.argv.slice(2));
    if (args.help) {
      printHelp();
      return;
    }
    if (!args.input) {
      printHelp();
      process.exitCode = 2;
      return;
    }

    const inputPath = path.resolve(args.input);
    const outputPath = path.resolve(args.output ?? defaultOutputPath(inputPath));
    const raw = await fs.readFile(inputPath, "utf8");
    const mermaid = extractMermaid(raw);

    if (!mermaid) {
      throw new Error("no Mermaid content found in input");
    }

    const parseMermaidToExcalidraw = await loadMermaidParser();
    const parsed = await parseMermaidToExcalidraw(mermaid);
    const normalized = normalizeParseResult(parsed);
    const conversion = await maybeConvertElements(normalized.elements, args.convert);

    const payload = {
      type: "excalidraw",
      version: 2,
      source: args.source,
      elements: conversion.elements,
      appState: {
        viewBackgroundColor: "#ffffff",
        gridSize: null,
      },
      files: normalized.files ?? {},
    };

    await fs.writeFile(outputPath, `${JSON.stringify(payload, null, 2)}\n`, "utf8");

    const convertedLabel = conversion.converted ? "converted=true" : "converted=false";
    console.log(`${outputPath} (${convertedLabel})`);
  } catch (error) {
    console.error(`ERROR: ${error instanceof Error ? error.message : String(error)}`);
    process.exitCode = 1;
  }
}

await main();
