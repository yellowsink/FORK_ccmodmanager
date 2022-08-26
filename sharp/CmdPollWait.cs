namespace CCModManager;

public unsafe class CmdPollWait : Cmd<string, bool?, object?[]?> {
	public override bool LogRun   => false;
	public override bool Taskable => true;
	public override object?[]? Run(string id, bool? skip) => CmdTasks.Get(id)?.Wait(skip ?? false);
}