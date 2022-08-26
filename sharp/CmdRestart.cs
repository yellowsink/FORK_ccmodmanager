using System;
using System.Diagnostics;
using System.IO;

namespace CCModManager;

public unsafe class CmdRestart : Cmd<string, string?> {

	public override string? Run(string exe) {
		Environment.SetEnvironmentVariable("LOCAL_LUA_DEBUGGER_VSCODE", "0");
		Environment.SetEnvironmentVariable("OLYMPUS_RESTARTER_PID",     Process.GetCurrentProcess().Id.ToString());

		var process = new Process();

		if (exe.EndsWith(".love")) {
			var sh = exe.Substring(0, exe.Length - 4) + "sh";
			if (File.Exists(sh))
				exe = sh;
		}

		process.StartInfo.FileName   = exe;
		Environment.CurrentDirectory = process.StartInfo.WorkingDirectory = Path.GetDirectoryName(exe)!;

		Console.Error.WriteLine($"Starting Olympus process: {exe}");
		process.Start();
		return null;
	}

}