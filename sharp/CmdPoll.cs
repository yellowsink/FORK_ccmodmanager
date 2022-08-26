namespace CCModManager;

public unsafe class CmdPoll : Cmd<string, object?> {
	public override bool   LogRun         => false;
	public override object? Run(string id) => CmdTasks.Get(id)?.Current;
}