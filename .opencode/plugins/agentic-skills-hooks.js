import fs from "node:fs";
import path from "node:path";
import { execSync } from "node:child_process";

const CONTEXT_HEAD_LIMIT = 500;

function isObject(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function normalizeCommand(command) {
  if (typeof command !== "string") return "";
  return command.replace(/\s+/g, " ").trim();
}

function extractCommand(args) {
  if (!isObject(args)) return "";

  if (typeof args.command === "string") return args.command;
  if (typeof args.cmd === "string") return args.cmd;
  if (typeof args.script === "string") return args.script;

  if (isObject(args.input)) return extractCommand(args.input);
  if (isObject(args.payload)) return extractCommand(args.payload);
  return "";
}

function setCommand(args, command) {
  if (!isObject(args)) return { command };
  if (typeof args.command === "string") {
    args.command = command;
    return args;
  }
  if (typeof args.cmd === "string") {
    args.cmd = command;
    return args;
  }
  if (typeof args.script === "string") {
    args.script = command;
    return args;
  }
  args.command = command;
  return args;
}

function shellEscapeSingleQuotes(value) {
  return value.replace(/'/g, `'\"'\"'`);
}

function blockCommand(reason) {
  return `printf '%s\\n' '${shellEscapeSingleQuotes(reason)}' >&2; exit 2`;
}

function isDangerousRm(command) {
  const rmRfPattern = /rm\s+(-[a-zA-Z]*r[a-zA-Z]*f|--recursive\s+--force|-[a-zA-Z]*f[a-zA-Z]*r)[a-zA-Z]*\s+(\/\s*$|\/\*|~\/?(\s|$)|\.\/?(\s|$)|\*(\s|$))/i;
  const noPreserveRoot = /rm\s+.*--no-preserve-root/i;
  return rmRfPattern.test(command) || noPreserveRoot.test(command);
}

function isDotEnvRead(command) {
  const envRead = /(cat|less|more|head|tail|source|\.)\s+[^\s]*\.env(\s|$)/i;
  const allowed = /\.(env\.example|env\.sample|env\.template|env\.test|env\.development\.local|env\.local\.example)(\s|$)/i;
  return envRead.test(command) && !allowed.test(command);
}

function readHead(filePath) {
  try {
    if (!fs.existsSync(filePath)) return "";
    return fs.readFileSync(filePath, "utf8").slice(0, CONTEXT_HEAD_LIMIT).trim();
  } catch {
    return "";
  }
}

function readDirNames(baseDir, fileExt = null) {
  try {
    if (!fs.existsSync(baseDir)) return [];
    const entries = fs.readdirSync(baseDir, { withFileTypes: true });
    if (fileExt) {
      return entries
        .filter((entry) => entry.isFile() && entry.name.endsWith(fileExt))
        .map((entry) => entry.name.replace(new RegExp(`${fileExt}$`), ""))
        .sort();
    }
    return entries
      .filter((entry) => entry.isDirectory())
      .map((entry) => entry.name)
      .sort();
  } catch {
    return [];
  }
}

function firstExistingPath(candidates) {
  for (const candidate of candidates) {
    if (fs.existsSync(candidate)) return candidate;
  }
  return null;
}

function gitInfo(directory) {
  try {
    const branch = execSync("git branch --show-current", {
      cwd: directory,
      stdio: ["ignore", "pipe", "ignore"],
      encoding: "utf8",
    }).trim() || "detached";

    const uncommitted = execSync("git status --porcelain", {
      cwd: directory,
      stdio: ["ignore", "pipe", "ignore"],
      encoding: "utf8",
    })
      .split("\n")
      .filter(Boolean).length;

    return `Git: branch=${branch}, uncommitted_files=${uncommitted}`;
  } catch {
    return "";
  }
}

function buildSessionStartContext(directory) {
  const parts = [`Date: ${new Date().toISOString().slice(0, 10)}`];
  const git = gitInfo(directory);
  if (git) parts.push(git);

  const contextFile = firstExistingPath([
    path.join(directory, ".claude", "CONTEXT.md"),
    path.join(directory, ".opencode", "CONTEXT.md"),
  ]);
  if (contextFile) {
    const content = readHead(contextFile);
    if (content) parts.push(`CONTEXT.md: ${content}`);
  }

  const todoFile = firstExistingPath([
    path.join(directory, ".claude", "TODO.md"),
    path.join(directory, ".opencode", "TODO.md"),
  ]);
  if (todoFile) {
    const content = readHead(todoFile);
    if (content) parts.push(`TODO.md: ${content}`);
  }

  return parts.join("\n").trim();
}

function buildCompactContext(directory) {
  const parts = ["CRITICAL CONTEXT TO PRESERVE AFTER COMPACTION:"];

  const skillsDir = firstExistingPath([
    path.join(directory, ".opencode", "skills"),
    path.join(directory, ".claude", "skills"),
  ]);
  const skillNames = skillsDir ? readDirNames(skillsDir) : [];
  if (skillNames.length > 0) {
    parts.push(`Skills (${skillNames.length}): ${skillNames.join(", ")}`);
  } else {
    parts.push("Skills: none found");
  }

  const agentsDir = firstExistingPath([
    path.join(directory, ".opencode", "agents"),
    path.join(directory, ".claude", "agents"),
  ]);
  const agentNames = agentsDir ? readDirNames(agentsDir, ".md") : [];
  if (agentNames.length > 0) {
    parts.push(`Agents (${agentNames.length}): ${agentNames.join(", ")}`);
  } else {
    parts.push("Agents: none found");
  }

  parts.push("Always use relevant skills for the task at hand.");
  return parts.join("\n");
}

async function injectContext(client, sessionID, context) {
  if (!context) return;
  await client.session.prompt({
    path: { id: sessionID },
    body: {
      noReply: true,
      parts: [{ type: "text", text: context, synthetic: true }],
    },
  });
}

function getSessionID(event) {
  if (!event || typeof event !== "object") return null;
  return event.properties?.info?.id || event.properties?.sessionID || event.session?.id || null;
}

function appendFailureLog(directory, event) {
  try {
    const logDir = path.join(directory, ".opencode", "hooks", "logs");
    fs.mkdirSync(logDir, { recursive: true });
    const logFile = path.join(logDir, "tool_failures.jsonl");
    const payload = {
      timestamp: new Date().toISOString(),
      type: event?.type || "unknown",
      properties: event?.properties || null,
    };
    fs.appendFileSync(logFile, `${JSON.stringify(payload)}\n`, "utf8");
  } catch {
    // Best-effort logging only.
  }
}

export const AgenticSkillsHooksPlugin = async ({ client, directory }) => {
  return {
    "tool.execute.before": async (input, output) => {
      const tool = String(input?.tool || "").toLowerCase();
      if (tool !== "bash" && tool !== "shell") return;

      const command = normalizeCommand(extractCommand(output?.args));
      if (!command) return;

      if (isDangerousRm(command)) {
        const reason = `BLOCKED: Dangerous rm -rf pattern detected: ${command}`;
        output.args = setCommand(output.args, blockCommand(reason));
        return;
      }

      if (isDotEnvRead(command)) {
        const reason = "BLOCKED: Direct .env file access detected. Use environment variables instead.";
        output.args = setCommand(output.args, blockCommand(reason));
      }
    },

    event: async ({ event }) => {
      const type = event?.type;
      const sessionID = getSessionID(event);

      if (type === "session.created" && sessionID) {
        await injectContext(client, sessionID, buildSessionStartContext(directory));
      }

      if (type === "session.compacted" && sessionID) {
        await injectContext(client, sessionID, buildCompactContext(directory));
      }

      if (type === "session.error") {
        appendFailureLog(directory, event);
      }
    },
  };
};

export default AgenticSkillsHooksPlugin;
