//FeatSub

package org.gmod.chado.chadxtogame;

public class FeatSub {
public String m_Id = null;
private SMTPTR m_TypeId = new SMTPTR("typeINIT");

	public FeatSub(String the_Id){
		m_Id = the_Id;
	}

	public void setId(String the_Id){
		m_Id = the_Id;
	}

	public String getId(){
		return m_Id;
	}

//TYPE_ID
	public void setTypeId(String the_TypeId){
		m_TypeId.setkey(the_TypeId);
	}

	public void setTypeId(Attrib the_gf){
		m_TypeId.setGF(the_gf);
	}

	public void setTypeId(SMTPTR the_SMTPTR){
		m_TypeId = the_SMTPTR;
	}

	public String getTypeId(){
		//System.out.println("GENFEAT:getTypeId()");
		return m_TypeId.getValue();
	}

	public String getTypeIdTxt(){
		System.out.println("GENFEAT:getTypeIdTxt()");
		if(m_TypeId.getObjValue()!=null){
			System.out.println("\tRETURNING<"+((CVTerm)m_TypeId.getObjValue()).getname()+">");
		}else{
			System.out.println("\tRETURNING<NULL>");
		}
		if(m_TypeId.getObjValue()!=null){
			return ((CVTerm)m_TypeId.getObjValue()).getname();
		}
		return null;
	}

	public void Display(int the_depth){
		if(this instanceof FeatProp){
			((FeatProp)this).Display(the_depth);
		}else if(this instanceof FeatProp){
			((FeatDbxref)this).Display(the_depth);
		}
	}
}

