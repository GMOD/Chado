//Aspect
package org.gmod.chado.gametochadx;

import org.gmod.chado.gametochadx.GenFeat;
import java.util.*;

public class Aspect extends GenFeat {
private String m_function;
//GUESSING ABOUT THE FOLLOWING TWO, HAVE NOT SEEN EXAMPLES
private String m_process;
private String m_component;

	public Aspect(){
		super("aspect");
	}

	public void setFunction(String the_function){
		m_function = the_function;
	}

	public String getFunction(){
		return m_function;
	}

	public void setProcess(String the_process){
		m_process = the_process;
	}

	public String getProcess(){
		return m_process;
	}

	public void setComponent(String the_component){
		m_component = the_component;
	}

	public String getComponent(){
		return m_component;
	}
}

