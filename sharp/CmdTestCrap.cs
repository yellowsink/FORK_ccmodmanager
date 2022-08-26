namespace CCModManager;

public unsafe class CmdTestCrap : Cmd<string, string>
{
	public override string Run(string data) => data;
}