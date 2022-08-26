using System;
using Microsoft.Win32;

namespace CCModManager;

public static class Win32RegHelper {

	public static RegistryKey? OpenOrCreateKey(string path, bool writable) {
		// the compiler gets angy (rightly so!) about Registry being in the code path on unix
		// so this check quiets down the warnings
		// it also has the side effect of replacing some `PlatformNotSupportedException`s with a null return
		// -- yellowsink 2022-08-25
		if (!OperatingSystem.IsWindows()) return null;
		
		
		var parts = path.Split('\\');
            
		RegistryKey? key;
		switch (parts[0].ToUpperInvariant()) {
			case "HKEY_CURRENT_USER":
			case "HKCU":
				key = Registry.CurrentUser;
				break;

			case "HKEY_LOCAL_MACHINE":
			case "HKLM":
				key = Registry.LocalMachine;
				break;

			case "HKEY_CLASSES_ROOT":
			case "HKCR":
				key = Registry.ClassesRoot;
				break;

			case "HKEY_USERS":
				key = Registry.Users;
				break;

			case "HKEY_CURRENT_CONFIG":
				key = Registry.CurrentConfig;
				break;

			default:
				return null;
		}

		if (writable) {
			for (var i = 1; i < parts.Length; i++)
				key = key.OpenSubKey(parts[i], true) ?? key.CreateSubKey(parts[i]);
		} else {
			for (var i = 1; i < parts.Length && key != null; i++)
				key = key.OpenSubKey(parts[i], false);
		}

		return key;
	}

}