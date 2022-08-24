using Mono.Cecil;
using Mono.Cecil.Cil;
using MonoMod.Utils;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace CCModManager {
    class Package
    {
        public string name { get; set; }
        public string version { get; set; }
    }
    class Changelog {
        public class ChangelogItem
        {
            public string version { get; set; }
        }
        public ChangelogItem[] changelog { get; set; }
    }

    public class CmdGetVersionString : Cmd<string, string> {

        public override bool Taskable => true;

        public override string Run(string root) {
            Tuple<string, Version, Version> data = GetVersion(root);
            return data.Item1;
        }

        public static Tuple<string, Version, Version> GetVersion(string root) {
            try
            {
                Changelog.ChangelogItem[] changelog;
                using (StreamReader reader = new StreamReader(Path.Combine(root, "assets", "data", "changelog.json")))
                using (JsonTextReader json = new JsonTextReader(reader))
                {
                    Changelog data = JsonSerializer.Create().Deserialize(json, typeof(Changelog)) as Changelog;
                    changelog = data.changelog;
                }

                string versionString = changelog[0].version;
                List<int> versionInts = new List<int>();
                foreach (var num in versionString.Split('.'))
                {
                    versionInts.Add(Int32.Parse(num));
                }

                Version version = new Version();
                if (versionInts == null || versionInts.Count == 0)
                    version = new Version();
                else if (versionInts.Count == 2)
                    version = new Version(versionInts[0], versionInts[1]);
                else if (versionInts.Count == 3)
                    version = new Version(versionInts[0], versionInts[1], versionInts[2]);
                else if (versionInts.Count == 4)
                    version = new Version(versionInts[0], versionInts[1], versionInts[2], versionInts[3]);

                string status = $"CrossCode {version}";

                if (File.Exists(Path.Combine(root, "ccloader", "package.json")))
                {
                    Package package;
                    using (StreamReader reader = new StreamReader(Path.Combine(root, "ccloader", "package.json")))
                    using (JsonTextReader json = new JsonTextReader(reader))
                    {
                        Package data = JsonSerializer.Create().Deserialize(json, typeof(Package)) as Package;
                        package = data;
                    }

                    if (package.version != null)
                    {
                        status = $"{status} + CCLoader {package.version}";
                    }
                }

                return new Tuple<string, Version, Version>(status, null, null);
            } catch (Exception e) {
                return new Tuple<string, Version, Version>($"? - {e.Message}", null, null);
            }
        }

    }
}
