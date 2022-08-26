using System;
using System.Diagnostics;
using System.IO;

namespace CCModManager;

public unsafe class CmdLaunch : Cmd<string, string, bool, string?> {

	public override bool Taskable => true;

	public override string? Run(string root, string args, bool force) {
		if (!force && !string.IsNullOrEmpty(Cmds.Get<CmdGetRunningPath>()?.Run(root, "CrossCode")))
			return "running";

		Environment.SetEnvironmentVariable("LOCAL_LUA_DEBUGGER_VSCODE", "0");

		var game = new Process();

		if (Environment.OSVersion.Platform == PlatformID.Unix) {
			game.StartInfo.FileName = Path.Combine(root, "CrossCode");
			if (!File.Exists(game.StartInfo.FileName) && Path.GetFileName(root) == "Resources")
				game.StartInfo.FileName = Path.Combine(Path.GetDirectoryName(root)!, "MacOS", "nwjs");
		} else
			game.StartInfo.FileName = Path.Combine(root, "CrossCode.exe");

		if (!File.Exists(game.StartInfo.FileName)) {
			Console.Error.WriteLine($"Can't start CrossCode: {game.StartInfo.FileName} not found!");
			return "missing";
		}

		Environment.CurrentDirectory = game.StartInfo.WorkingDirectory = Path.GetDirectoryName(game.StartInfo.FileName)!;

		if (args?.Trim() == "--vanilla")
		{
			// Thank Dima for the brilliance of CCLOADER_OVERRIDE_MAIN_URL,
			// if not for the translateinator this environment variable might not have existed
			game.StartInfo.UseShellExecute = false;
			game.StartInfo.EnvironmentVariables.Add("CCLOADER_OVERRIDE_MAIN_URL", "/assets/node-webkit.html");
		}

		if (!string.IsNullOrEmpty(args))
			game.StartInfo.Arguments = args;

		Console.Error.WriteLine($"Starting CrossCode process: {game.StartInfo.FileName} {(string.IsNullOrEmpty(args) ? "(without args)" : args)}");

		game.Start();
		return null;
	}

}