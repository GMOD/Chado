//FeatAnal
package conv.chadxtogame;

import java.util.*;

public class FeatAnal extends FeatSub {

private String m_rawscore = null;
private String m_sourcename = null;
private String m_program = null;
private String m_programversion = null;

private SMTPTR m_SynonymId = new SMTPTR("synonym");
private SMTPTR m_PubId = new SMTPTR("pub");

	public FeatAnal(String the_Id){
		super(the_Id);
	}

	public void setrawscore(String the_rawscore){
		m_rawscore = the_rawscore;
	}

	public String getrawscore(){
		return m_rawscore;
	}

	public void setsourcename(String the_sourcename){
		m_sourcename = the_sourcename;
	}

	public String getsourcename(){
		return m_sourcename;
	}

	public void setprogram(String the_program){
		m_program = the_program;
	}

	public String getprogram(){
		return m_program;
	}

	public void setprogramversion(String the_programversion){
		m_programversion = the_programversion;
	}

	public String getprogramversion(){
		return m_programversion;
	}
}


