using System;
using System.IO;
using System.Linq;
using System.Text.Json;

// ReSharper disable InconsistentNaming

namespace CCModManager;

internal record Package(string name, string version);

// ReSharper disable once ClassNeverInstantiated.Global
internal record ChangelogItem(string      version);
internal record Changelog(ChangelogItem[] changelog);

public class CmdGetVersionString : Cmd<string, string> {

	public override bool Taskable => true;

	public override string Run(string root)
	{
		try
		{
			var clPath    = Path.Combine(root, "assets", "data", "changelog.json");
			var changelog = JsonSerializer.Deserialize<Changelog>(File.ReadAllText(clPath))!.changelog;

			var versionString = changelog[0].version;
			var versionInts   = versionString.Split('.').Select(int.Parse).ToList();

			var version = versionInts.Count switch
			{
				//0 => new Version(),
				2 => new Version(versionInts[0], versionInts[1]),
				3 => new Version(versionInts[0], versionInts[1], versionInts[2]),
				4 => new Version(versionInts[0], versionInts[1], versionInts[2], versionInts[3]),
				_ => new Version()
			};

			var status = $"CrossCode {version}";

			var jsonPath = Path.Combine(root, "ccloader", "package.json");
			if (File.Exists(jsonPath))
			{
				var package = JsonSerializer.Deserialize<Package>(File.ReadAllText(jsonPath));
					
				if (package?.version != null) status += $" + CCLoader {package.version}";
			}

			return status;
		} 
		catch (Exception e)
		{
			return $"? - {e.Message}";
		}
	}
}