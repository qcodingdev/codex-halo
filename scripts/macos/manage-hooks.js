ObjC.import("Foundation");

const events = [
  "UserPromptSubmit",
  "PreToolUse",
  "PostToolUse",
  "PermissionRequest",
  "Stop",
];
const marker = "/.codex-halo/codex-halo-hook.sh";

function readText(path) {
  const data = $.NSData.dataWithContentsOfFile(path);
  if (!data) return null;
  return ObjC.unwrap($.NSString.alloc.initWithDataEncoding(data, $.NSUTF8StringEncoding));
}

function writeText(path, text) {
  const value = $(text);
  const ok = value.writeToFileAtomicallyEncodingError(
    path,
    true,
    $.NSUTF8StringEncoding,
    null,
  );
  if (!ok) throw new Error("Could not atomically write " + path);
}

function isHaloHandler(handler) {
  return (
    handler &&
    typeof handler === "object" &&
    typeof handler.command === "string" &&
    handler.command.includes(marker)
  );
}

function validateHooks(hooks) {
  if (!hooks || typeof hooks !== "object" || Array.isArray(hooks)) {
    throw new Error("The top-level hooks value must be an object.");
  }
  Object.keys(hooks).forEach((eventName) => {
    if (!Array.isArray(hooks[eventName])) {
      throw new Error("hooks." + eventName + " must be an array.");
    }
    hooks[eventName].forEach((group) => {
      if (!group || typeof group !== "object" || !Array.isArray(group.hooks)) {
        throw new Error("Every hook matcher group must contain a hooks array.");
      }
    });
  });
}

function removeHaloHandlers(hooks) {
  Object.keys(hooks).forEach((eventName) => {
    hooks[eventName] = hooks[eventName]
      .map((group) => ({
        ...group,
        hooks: group.hooks.filter((handler) => !isHaloHandler(handler)),
      }))
      .filter((group) => group.hooks.length > 0);
    if (hooks[eventName].length === 0) delete hooks[eventName];
  });
}

function countHaloHandlers(hooks) {
  let count = 0;
  Object.keys(hooks).forEach((eventName) => {
    hooks[eventName].forEach((group) => {
      count += group.hooks.filter((handler) => isHaloHandler(handler)).length;
    });
  });
  return count;
}

function run(argv) {
  if (argv.length < 2) {
    throw new Error("Usage: manage-hooks.js install|uninstall|verify path [command]");
  }
  const operation = argv[0];
  const path = argv[1];
  const command = argv[2] || "";
  const text = readText(path);
  const document = text
    ? JSON.parse(text)
    : { description: "User lifecycle hooks.", hooks: {} };

  if (!document || typeof document !== "object" || Array.isArray(document)) {
    throw new Error("hooks.json must contain a JSON object.");
  }
  if (!Object.prototype.hasOwnProperty.call(document, "hooks")) document.hooks = {};
  validateHooks(document.hooks);

  if (operation === "verify") {
    return String(countHaloHandlers(document.hooks));
  }

  removeHaloHandlers(document.hooks);
  if (operation === "install") {
    if (!command.includes(marker)) throw new Error("Unexpected Halo hook command.");
    events.forEach((eventName) => {
      if (!document.hooks[eventName]) document.hooks[eventName] = [];
      document.hooks[eventName].push({
        hooks: [{ type: "command", command, timeout: 3 }],
      });
    });
  } else if (operation !== "uninstall") {
    throw new Error("Unknown operation: " + operation);
  }

  writeText(path, JSON.stringify(document, null, 2) + "\n");
  return String(countHaloHandlers(document.hooks));
}
