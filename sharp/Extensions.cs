using System;
using System.IO;

namespace CCModManager;

/*
internal class TeeStream : Stream
{
	public TeeStream(Stream d1, Stream d2)
	{
		_Dest1 = d1;
		_Dest2 = d2;
	}

	private readonly Stream _Dest1;
	private readonly Stream _Dest2;

	public override void Flush()
	{
		_Dest1.Flush();
		_Dest2.Flush();
	}

	public override int Read(byte[] buffer, int offset, int count) => throw new NotSupportedException("cant read a TeeStream");

	public override long Seek(long offset, SeekOrigin origin) => throw new NotSupportedException("cant seek a TeeStream");

	public override void SetLength(long value) => throw new NotSupportedException("cant seek a TeeStream");

	public override void Write(byte[] buffer, int offset, int count)
	{
		_Dest1.Write(buffer, offset, count);
		_Dest2.Write(buffer, offset, count);
	}

	public override bool CanRead  => false;
	public override bool CanSeek  => false;
	public override bool CanWrite => true;
	public override long Length   => throw new NotSupportedException("cant seek a TeeStream");
	public override long Position
	{
		get => throw new NotSupportedException("cant seek a TeeStream");
		set => throw new NotSupportedException("cant seek a TeeStream");
	}
}
*/

public static class Extensions {

	public static bool ReadLineUntil(this TextReader reader, string wanted) {
		for (string? line; (line = reader.ReadLine()?.TrimEnd()) != null;)
			if (line == wanted)
				return true;
		return false;
	}

/*
	public static (Stream source, Stream dest2) Tee(this Stream dest1)
	{
		var s2 = new MemoryStream();
		return (new TeeStream(dest1, s2), s2);
	}
*/
}