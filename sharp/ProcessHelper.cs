using System;
using System.Diagnostics;

namespace CCModManager;

public static class ProcessHelper {
	private static Process Wrap(string name, string args) {
		var process = new Process();

		process.StartInfo.FileName  = name;
		process.StartInfo.Arguments = args;

		process.StartInfo.UseShellExecute        = false;
		process.StartInfo.CreateNoWindow         = true;
		process.StartInfo.RedirectStandardOutput = true;
		process.StartInfo.StandardOutputEncoding = Program.UTF8NoBOM;
		process.StartInfo.RedirectStandardError  = true;
		process.StartInfo.StandardErrorEncoding  = Program.UTF8NoBOM;

		return process;
	}

	public static string Read(string name, string args, out string err) {
		try
		{
			using var process = Wrap(name, args);
			
			process.Start();
			process.WaitForExit();
			err = process.StandardError.ReadToEnd().Trim();
			return process.StandardOutput.ReadToEnd().Trim();
		} catch (Exception e) {
			Console.Error.WriteLine($"Reading from process \"{name}\" \"{args}\" failed:");
			Console.Error.WriteLine(e);
			err = "";
			return "";
		}
	}

	public static string ReadTimeout(string name, string args, int timeout, out string err) {
		// FIXME: WaitForExit isn't brutal enough on macOS. Maybe use a separate thread?
		try
		{
			using var process = Wrap(name, args);
			
			process.Start();
			process.WaitForExit(timeout);
			err = process.StandardError.ReadToEnd().Trim();
			return process.StandardOutput.ReadToEnd().Trim();
		} catch (Exception e) {
			Console.Error.WriteLine($"Reading from process \"{name}\" \"{args}\" failed:");
			Console.Error.WriteLine(e);
			err = "";
			return "";
		}
	}

	public static int RunAs(string name, string args) {
		var process = new Process();

		process.StartInfo.FileName  = name;
		process.StartInfo.Arguments = args;
		process.StartInfo.Verb      = "RunAs";

		process.Start();
		process.WaitForExit();
		return process.ExitCode;
	}

}