//DATE
package org.gmod.chado.gametochadx;

//import java.util.*;

public class Date {
private String m_timestamp;
private String m_date;

	public Date(String the_timestamp){
		m_timestamp = the_timestamp;
	}

	public void settimestamp(String the_timestamp){
		m_timestamp = the_timestamp;
	}

	public String gettimestamp(){
		return m_timestamp;
	}

	public void setdate(String the_date){
		m_date = the_date;
	}

	public String getdate(){
		return m_date;
	}
}

