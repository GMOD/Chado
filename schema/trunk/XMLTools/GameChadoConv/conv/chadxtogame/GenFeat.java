//GENFEAT

package conv.chadxtogame;

import java.util.*;

public class GenFeat extends FeatSub {

private String m_Name;
private String m_UniqueName;

private FeatLoc m_FeatLoc;
private FeatLoc m_AltFeatLoc;
private Vector m_ComponentList = null;

	public GenFeat(String the_Id){
		super(the_Id);
		m_ComponentList = new Vector();
	}

	public void setName(String the_Name){
		m_Name = the_Name;
	}

	public String getName(){
		return m_Name;
	}

	public void setUniqueName(String the_UniqueName){
		m_UniqueName = the_UniqueName;
	}

	public String getUniqueName(){
		return m_UniqueName;
	}

	public void setFeatLoc(FeatLoc the_FeatLoc){
		m_FeatLoc = the_FeatLoc;
	}

	public FeatLoc getFeatLoc(){
		return m_FeatLoc;
	}

	public void setAltFeatLoc(FeatLoc the_AltFeatLoc){
		m_AltFeatLoc = the_AltFeatLoc;
	}

	public FeatLoc getAltFeatLoc(){
		return m_AltFeatLoc;
	}

	public int getGenFeatCount(){
		if(m_ComponentList!=null){
			return m_ComponentList.size();
		}else{
			return 0;
		}
	}

	public void addGenFeat(FeatSub the_GenFeat){
		m_ComponentList.add(the_GenFeat);
	}

	public FeatSub getGenFeat(int the_indx){
		if((the_indx>=0)&&(m_ComponentList!=null)&&(the_indx<m_ComponentList.size())){
			return (FeatSub)m_ComponentList.get(the_indx);
		}else{
			return null;
		}
	}

	public void removeGenFeat(int the_index){
		m_ComponentList.remove(the_index);
	}
}

