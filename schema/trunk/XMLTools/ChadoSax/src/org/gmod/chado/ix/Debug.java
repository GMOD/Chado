//flybase/util/Debug.java
// d.g.gilbert 


//from package flybase.util;
package org.gmod.chado.ix;

import java.io.PrintStream;


public final class Debug {
	public static boolean isOn = false;
	public static PrintStream out= System.err; //System.out
	public static PrintStream err= System.err;
	static { isOn= (System.getProperty("debug")!=null); }
	protected static int val;
	
	public final static int val() { return val; }
	public final static void setPr(PrintStream printer) { out= printer; }
	public final static void setVal(int v) { val= v; isOn= (val!=0); }
	public final static void setState(boolean turnon) { isOn= turnon; }
	public final static boolean getState() { return isOn; }
	public final static void print(char c) { if (isOn) out.print(c); }
	public final static void print(String s) { if (isOn) out.print(s); }
	public final static void println(String s) { if (isOn) out.println(s); }
	public final static void println() { if (isOn) out.println(); }

	public final static void setErrorPr(PrintStream printer) { err= printer; }
	public final static void errprint(String s) { err.print(s); }
	public final static void errprintln(String s) { err.println(s); }
};

