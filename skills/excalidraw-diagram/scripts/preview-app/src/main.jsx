import React, { useEffect, useState, useRef, useCallback } from "react";
import { createRoot } from "react-dom/client";
import { Excalidraw, restoreElements } from "@excalidraw/excalidraw";
import "@excalidraw/excalidraw/index.css";

// Compute a fingerprint of elements to detect real changes
function fingerprint(elements) {
  const active = elements.filter((e) => !e.isDeleted);
  const count = active.length;
  const vsum = active.reduce((s, e) => s + (e.version || 0), 0);
  return `${count}:${vsum}`;
}

function App() {
  const [initialData, setInitialData] = useState(null);
  const [status, setStatus] = useState("loading");
  const [fileVersion, setFileVersion] = useState(-1);
  const excalidrawRef = useRef(null);
  const suppressPollUntil = useRef(0);
  const suppressSaveUntil = useRef(0);
  const readyForSave = useRef(false);
  const saveTimerRef = useRef(null);
  const knownFingerprint = useRef("0:0");

  // Load initial scene
  useEffect(() => {
    fetch("/api/scene.json")
      .then((r) => r.json())
      .then((scene) => {
        const restored = restoreElements(
          (scene.elements || []).filter((e) => !e.isDeleted),
          null
        );
        // Record fingerprint so we don't save unchanged data
        knownFingerprint.current = fingerprint(restored);
        setInitialData({
          elements: restored,
          appState: {
            viewBackgroundColor:
              scene.appState?.viewBackgroundColor || "#ffffff",
          },
          files: scene.files || {},
          scrollToContent: true,
        });
        setFileVersion(0);
        setStatus("ready");
      })
      .catch((err) => setStatus("error: " + err.message));
  }, []);

  // Poll for file changes from AI agent edits
  useEffect(() => {
    if (fileVersion < 0) return;

    const interval = setInterval(async () => {
      if (Date.now() < suppressPollUntil.current) return;
      try {
        const res = await fetch("/api/version");
        const v = parseInt(await res.text());
        if (v > fileVersion) {
          const sceneRes = await fetch("/api/scene.json?t=" + Date.now());
          const scene = await sceneRes.json();
          const api = excalidrawRef.current;
          if (api) {
            // Cancel pending saves
            if (saveTimerRef.current) {
              clearTimeout(saveTimerRef.current);
              saveTimerRef.current = null;
            }
            suppressSaveUntil.current = Date.now() + 5000;

            const restored = restoreElements(
              (scene.elements || []).filter((e) => !e.isDeleted),
              null
            );
            api.updateScene({ elements: restored });

            // Update fingerprint so onChange won't re-save this state
            // Use a slight delay to capture the fingerprint AFTER Excalidraw processes the update
            setTimeout(() => {
              const currentEls = api.getSceneElements();
              knownFingerprint.current = fingerprint(currentEls);
            }, 500);
          }
          setFileVersion(v);
          setStatus(`synced v${v}`);
        }
      } catch {}
    }, 1000);

    return () => clearInterval(interval);
  }, [fileVersion]);

  // Save browser edits back to file — only when user makes real changes
  const handleChange = useCallback((elements, appState) => {
    if (!readyForSave.current) return;
    if (Date.now() < suppressSaveUntil.current) return;

    const fp = fingerprint(elements);
    if (fp === knownFingerprint.current) return;

    // Clear previous pending save
    if (saveTimerRef.current) {
      clearTimeout(saveTimerRef.current);
    }

    saveTimerRef.current = setTimeout(() => {
      saveTimerRef.current = null;
      if (Date.now() < suppressSaveUntil.current) return;

      const api = excalidrawRef.current;
      const currentElements = api ? api.getSceneElements() : elements;
      const currentAppState = api ? api.getAppState() : appState;

      // Check fingerprint one more time
      const currentFp = fingerprint(currentElements);
      if (currentFp === knownFingerprint.current) return;

      knownFingerprint.current = currentFp;
      suppressPollUntil.current = Date.now() + 3000;

      fetch("/api/save", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          type: "excalidraw",
          version: 2,
          source: "https://excalidraw.com",
          elements: currentElements,
          appState: {
            viewBackgroundColor:
              currentAppState?.viewBackgroundColor || "#ffffff",
            gridSize: currentAppState?.gridSize || null,
          },
          files: {},
        }),
      })
        .then(() => setStatus("saved"))
        .catch(() => setStatus("save failed"));
    }, 2000);
  }, []);

  if (!initialData) {
    return (
      <div
        style={{
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          height: "100vh",
          fontFamily: "system-ui",
          color: "#64748b",
          fontSize: "18px",
        }}
      >
        {status === "loading" ? "Loading diagram..." : `Error: ${status}`}
      </div>
    );
  }

  return (
    <div style={{ width: "100vw", height: "100vh" }}>
      <Excalidraw
        excalidrawAPI={(api) => {
          excalidrawRef.current = api;
          setTimeout(() => {
            // Set fingerprint from current rendered state
            knownFingerprint.current = fingerprint(api.getSceneElements());
            readyForSave.current = true;
          }, 3000);
        }}
        initialData={initialData}
        onChange={handleChange}
      />
    </div>
  );
}

createRoot(document.getElementById("root")).render(<App />);
