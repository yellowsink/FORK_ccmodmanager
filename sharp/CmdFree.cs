namespace CCModManager;

public unsafe class CmdFree : Cmd<string, string?> {
	public override bool LogRun => false;
	public override string? Run(string id) {
		var task   = CmdTasks.Remove(id);
		var status = task?.Status;
		task?.Dispose();
		return status;
	}
}