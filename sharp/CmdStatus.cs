using System;

namespace CCModManager;

public unsafe class CmdStatus : Cmd<string, object[]> {
	public override bool LogRun => false;
	public override object[] Run(string id) {
		var task = CmdTasks.Get(id);
		return task == null ? Array.Empty<object>() : new object[] { task.Status, task.Queue.Count };
	}
}