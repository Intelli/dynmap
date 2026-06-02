package org.dynmap.bukkit;

import java.lang.reflect.Constructor;

import org.bukkit.Bukkit;
import org.dynmap.Log;
import org.dynmap.bukkit.helper.BukkitVersionHelper;

public class Helper {

	private static BukkitVersionHelper loadVersionHelper(String classname) {
		try {
			Class<?> c = Class.forName(classname);
			Constructor<?> cons = c.getConstructor();
			return (BukkitVersionHelper) cons.newInstance();
		} catch (Exception x) {
			Log.severe("Error loading " + classname, x);
			return null;
		}
	}

	private static boolean isAtLeast12110(String serverVersion) {
		int mc = serverVersion.indexOf("(MC: ");
		if (mc < 0) {
			return false;
		}
		String mcver = serverVersion.substring(mc + 5);
		int end = mcver.indexOf(')');
		if (end > 0) {
			mcver = mcver.substring(0, end);
		}
		String[] parts = mcver.split("\\.");
		if (parts.length < 3) {
			return false;
		}
		try {
			int major = Integer.parseInt(parts[0]);
			int minor = Integer.parseInt(parts[1]);
			int patch = Integer.parseInt(parts[2]);
			if (major > 1 || (major == 1 && minor > 21)) {
				return true;
			}
			if (major == 1 && minor == 21) {
				return patch >= 10;
			}
		} catch (NumberFormatException ignored) {
		}
		return false;
	}

    public static final BukkitVersionHelper getHelper() {
        if (BukkitVersionHelper.helper == null) {
        	String v = Bukkit.getServer().getVersion();
            Log.info("version=" + v);
            if (!isAtLeast12110(v)) {
            	Log.severe("*********************************************************************************");
            	Log.severe("* Dynmap requires Minecraft 1.21.10 or newer (Spigot/Paper).                    *");
            	Log.severe("* This server reports: " + v);
            	Log.severe("*********************************************************************************");
            }
            else if (v.contains("(MC: 1.21.10)")) {
	            BukkitVersionHelper.helper = loadVersionHelper("org.dynmap.bukkit.helper.v121_10.BukkitVersionHelperSpigot121_10");
            }
            else if (v.contains("(MC: 1.21.")) {
	            BukkitVersionHelper.helper = loadVersionHelper("org.dynmap.bukkit.helper.v121_11.BukkitVersionHelperSpigot121_11");
            }
            else {
            	Log.severe("*********************************************************************************");
            	Log.severe("* Dynmap requires Minecraft 1.21.10 or newer (Spigot/Paper).                    *");
            	Log.severe("* This server reports: " + v);
            	Log.severe("*********************************************************************************");
            }
        }
        return BukkitVersionHelper.helper;
    }

}
