//SeqRel
package conv.gametochadx;

import java.util.*;

public class SeqRel extends GenFeat {
private String m_seqType;
private String m_seqLabel;
private String m_Alignment;

	public SeqRel(String the_id){
		super(the_id);
	}

	public void setSeqType(String the_seqType){
		m_seqType = the_seqType;
	}

	public String getSeqType(){
		return m_seqType;
	}

	public void setSeqLabel(String the_seqLabel){
		m_seqLabel = the_seqLabel;
	}

	public String getSeqLabel(){
		return m_seqLabel;
	}

	public void setAlignment(String the_Alignment){
		m_Alignment = the_Alignment;
	}

	public String getAlignment(){
		return m_Alignment;
	}
}

