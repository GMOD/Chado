//FeatSyn
package conv.chadxtogame;

import java.util.*;

public class FeatSyn extends FeatSub {

private String m_isinternal = null;
private String m_iscurrent = null;

private SMTPTR m_SynonymId = new SMTPTR("synonym");
private SMTPTR m_PubId = new SMTPTR("pub");

	public FeatSyn(String the_Id){
		super(the_Id);
	}

	public void setisinternal(String the_isinternal){
		m_isinternal = the_isinternal;
	}

	public String getisinternal(){
		return m_isinternal;
	}

	public void setiscurrent(String the_iscurrent){
		m_iscurrent = the_iscurrent;
	}

	public String getiscurrent(){
		return m_iscurrent;
	}

	public void setSynonymId(String the_SynonymId){
		m_SynonymId.setkey(the_SynonymId);
	}

	public void setSynonymId(FeatSub the_gf){
		m_SynonymId.setGF(the_gf);
	}

	public void setSynonymId(SMTPTR the_SMTPTR){
		m_SynonymId = the_SMTPTR;
	}

	public String getSynonymId(){
		//System.out.println("FEATURE:getSynonymId()");
		return m_SynonymId.getValue();
	}

	public Synonym getSynonym(){
		//System.out.println("FEATURE:getSynonym()");
		return (Synonym)m_SynonymId.getObjValue();
	}

	public void setPubId(String the_PubId){
		m_PubId.setkey(the_PubId);
	}

	public void setPubId(FeatSub the_gf){
		m_PubId.setGF(the_gf);
	}

	public void setPubId(SMTPTR the_SMTPTR){
		m_PubId = the_SMTPTR;
	}

	public String getPubId(){
		//System.out.println("FEATURE:getPubId()");
		return m_PubId.getValue();
	}

	public Pub getPub(){
		//System.out.println("FEATURE:getPub()");
		return (Pub)m_PubId.getObjValue();
	}
}


