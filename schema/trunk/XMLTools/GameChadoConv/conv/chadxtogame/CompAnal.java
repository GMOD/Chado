//COMP_ANAL

package conv.chadxtogame;

//FOR chado,feature
import java.util.*;

public class CompAnal extends GenFeat {

private Span m_Span;
private Span m_AltSpan;

private String m_Database;
private String m_Program;
private String m_SourceName;
private String m_ProgramVersion;
private String m_rawscore;


	public CompAnal(String the_Id){
		super(the_Id);
	}

	public void setSpan(Span the_Span){
		m_Span = the_Span;
	}

	public Span getSpan(){
		return m_Span;
	}

	public void setAltSpan(Span the_AltSpan){
		m_AltSpan = the_AltSpan;
	}

	public Span getAltSpan(){
		return m_AltSpan;
	}

	public void setrawscore(String the_rawscore){
		m_rawscore = the_rawscore;
	}

	public String getrawscore(){
		return m_rawscore;
	}

	public void setDatabase(String the_Database){
		m_Database = the_Database;
	}

	public String getDatabase(){
		return m_Database;
	}

	public void setProgram(String the_Program){
		m_Program = the_Program;
	}

	public String getProgram(){
		return m_Program;
	}

	public void setSourceName(String the_SourceName){
		m_SourceName = the_SourceName;
	}

	public String getSourceName(){
		return m_SourceName;
	}

	public void setProgramVersion(String the_ProgramVersion){
		m_ProgramVersion = the_ProgramVersion;
	}

	public String getProgramVersion(){
		return m_ProgramVersion;
	}
}

