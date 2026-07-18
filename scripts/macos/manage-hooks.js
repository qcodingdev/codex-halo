ObjC.import("Foundation");

const events = [
  "UserPromptSubmit",
  "PreToolUse",
  "PostToolUse",
  "PermissionRequest",
  "Stop",
];
const marker = "/.codex-halo/codex-halo-hook.sh";
const begin = "# >>> Codex Halo managed hooks >>>";
const end = "# <<< Codex Halo managed hooks <<<";

function readText(path) {
  const data = $.NSData.dataWithContentsOfFile(path);
  if (!data) return null;
  return ObjC.unwrap($.NSString.alloc.initWithDataEncoding(data, $.NSUTF8StringEncoding));
}

function writeText(path, text) {
  const ok = $(text).writeToFileAtomicallyEncodingError(
    path,
    true,
    $.NSUTF8StringEncoding,
    null,
  );
  if (!ok) throw new Error("Could not atomically write " + path);
}

function isHaloHandler(handler) {
  return handler && typeof handler === "object" && typeof handler.command === "string" && handler.command.includes(marker);
}

function validateHooks(hooks) {
  if (!hooks || typeof hooks !== "object" || Array.isArray(hooks)) throw new Error("The top-level hooks value must be an object.");
  Object.keys(hooks).forEach((eventName) => {
    if (!Array.isArray(hooks[eventName])) throw new Error("hooks." + eventName + " must be an array.");
    hooks[eventName].forEach((group) => {
      if (!group || typeof group !== "object" || !Array.isArray(group.hooks)) throw new Error("Every hook matcher group must contain a hooks array.");
    });
  });
}

function removeHaloHandlers(hooks) {
  Object.keys(hooks).forEach((eventName) => {
    hooks[eventName] = hooks[eventName].map((group) => ({ ...group, hooks: group.hooks.filter((handler) => !isHaloHandler(handler)) })).filter((group) => group.hooks.length > 0);
    if (hooks[eventName].length === 0) delete hooks[eventName];
  });
}

function countHaloHandlers(hooks) {
  return Object.keys(hooks).reduce((count, eventName) => count + hooks[eventName].reduce((sum, group) => sum + group.hooks.filter(isHaloHandler).length, 0), 0);
}

function manageJson(operation, path, command) {
  const text = readText(path);
  const document = text ? JSON.parse(text) : { description: "User lifecycle hooks.", hooks: {} };
  if (!document || typeof document !== "object" || Array.isArray(document)) throw new Error("hooks.json must contain a JSON object.");
  if (!Object.prototype.hasOwnProperty.call(document, "hooks")) document.hooks = {};
  validateHooks(document.hooks);
  if (operation === "verify") return String(countHaloHandlers(document.hooks));
  removeHaloHandlers(document.hooks);
  if (operation === "install") {
    if (!command.includes(marker)) throw new Error("Unexpected Halo hook command.");
    events.forEach((eventName) => {
      if (!document.hooks[eventName]) document.hooks[eventName] = [];
      document.hooks[eventName].push({ hooks: [{ type: "command", command, timeout: 3 }] });
    });
  } else if (operation !== "uninstall") {
    throw new Error("Unknown operation: " + operation);
  }
  writeText(path, JSON.stringify(document, null, 2) + "\n");
  return String(countHaloHandlers(document.hooks));
}

function managedSection(text) {
  const first = text.indexOf(begin);
  const last = text.lastIndexOf(begin);
  if (first === -1) {
    if (text.includes(end)) throw new Error("Codex Halo TOML marker is incomplete.");
    return { before: text, section: "", after: "" };
  }
  if (first !== last) throw new Error("More than one Codex Halo TOML block exists; stopping safely.");
  const finish = text.indexOf(end, first);
  if (finish === -1 || text.indexOf(end, finish + end.length) !== -1) throw new Error("Codex Halo TOML marker is incomplete.");
  const sectionEnd = finish + end.length;
  const afterStart = text.slice(sectionEnd).match(/^\r?\n/) ? sectionEnd + (text[sectionEnd] === "\r" ? 2 : 1) : sectionEnd;
  return { before: text.slice(0, first), section: text.slice(first, sectionEnd), after: text.slice(afterStart) };
}

function escapeToml(value) {
  return value.replace(/\\/g, "\\\\").replace(/"/g, '\\"');
}

function haloToml(command) {
  if (!command.includes(marker)) throw new Error("Unexpected Halo hook command.");
  const escaped = escapeToml(command);
  const entries = events.map((eventName) => `[[hooks.${eventName}]]\n[[hooks.${eventName}.hooks]]\ntype = "command"\ncommand = "${escaped}"\ntimeout = 3`).join("\n\n");
  return `${begin}\n# Installed by Codex Halo. Remove only with its uninstaller.\n${entries}\n${end}`;
}

function countTomlHandlers(section) {
  if (!section) return 0;
  return events.reduce((count, eventName) => count + (section.includes(`[[hooks.${eventName}]]`) && section.includes(`[[hooks.${eventName}.hooks]]`) ? 1 : 0), 0);
}

function manageToml(operation, path, command) {
  const original = readText(path) || "";
  const parsed = managedSection(original);
  if (operation === "verify") return String(countTomlHandlers(parsed.section));
  if (operation !== "install" && operation !== "uninstall") throw new Error("Unknown operation: " + operation);
  const retained = (parsed.before + parsed.after).replace(/\s+$/, "");
  const output = operation === "install" ? `${retained}${retained ? "\n\n" : ""}${haloToml(command)}\n` : (retained ? retained + "\n" : "");
  writeText(path, output);
  return operation === "install" ? "5" : "0";
}

function run(argv) {
  if (argv.length < 2) throw new Error("Usage: manage-hooks.js install|uninstall|verify path [command]");
  const [operation, path, command = ""] = argv;
  return path.endsWith(".json") ? manageJson(operation, path, command) : manageToml(operation, path, command);
}
