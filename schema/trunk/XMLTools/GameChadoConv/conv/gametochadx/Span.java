//Span
package conv.gametochadx;

import java.util.*;

public class Span {
private int m_start=0;
private int m_end=0;
private String m_src = null;

	public Span(String the_start,String the_end){
		try{
			m_start = Integer.decode(the_start).intValue();
			m_end = Integer.decode(the_end).intValue();
		}catch(Exception ex){
			System.out.println("SPAN STR ERROR <"
					+the_start+"><"+the_end+">");
			ex.printStackTrace();
		}
	}

	public Span(String the_start,String the_end,String the_src){
		this(the_start,the_end);
		m_src = the_src;
	}

	public Span(int the_start,int the_end){
		m_start = the_start;
		m_end = the_end;
	}

	public Span(int the_start,int the_end,String the_src){
		this(the_start,the_end);
		m_src = the_src;
	}

	public int getStart(){
		return m_start;
	}

	public int getEnd(){
		return m_end;
	}

	public void setSrc(String the_src){
		m_src = the_src;
	}

	public String getSrc(){
		return m_src;
	}

	public int getLength(){
		if(m_start<m_end){
			//return (m_end-m_start+1);
			return (m_end-m_start);
		}else{
			//return (m_start-m_end+1);
			return (m_start-m_end);
		}
	}

	public boolean isForward(){
		if(m_end>m_start){
			return true;
		}else{
			return false;
		}
	}

	public String toString(){
		return (m_start+".."+m_end);
	}

	public Span advance(int the_amt){
		if(m_end>m_start){
			return (new Span((m_start+the_amt-1),(m_end+the_amt),m_src));
		}else{
			return (new Span((m_start+the_amt),(m_end+the_amt-1),m_src));
		}
	}

	public Span retreat(int the_amt){
		if(m_end>m_start){
			return (new Span((m_start-the_amt+1),(m_end-the_amt),m_src));
		}else{
			return (new Span((m_start-the_amt),(m_end-the_amt+1),m_src));
		}
	}

	public Span union(Span the_sp){
		int minStart = m_start;
		int maxEnd = m_end;
		if(the_sp.isForward()){
			if(minStart>the_sp.getStart()){
				minStart = the_sp.getStart();
			}
			if(maxEnd<the_sp.getEnd()){
				maxEnd = the_sp.getEnd();
			}
		}else{
			if(minStart<the_sp.getStart()){
				minStart = the_sp.getStart();
			}
			if(maxEnd>the_sp.getEnd()){
				maxEnd = the_sp.getEnd();
			}
		}
		return new Span(minStart,maxEnd,m_src);
	}

	public boolean precedes(Span the_sp){
                if(the_sp==null){
                        return false;
                }
                if((isForward())&&(the_sp.isForward())){
                        if(getStart()<the_sp.getStart()){
                                return true;
                        }
                }else if((!isForward())&&(!isForward())){
                        if(getStart()>the_sp.getStart()){
                                return true;
                        }
                }else if((isForward())&&(!the_sp.isForward())){
                        System.out.println("FEATLOC PRECEDES() MIX1");
                }else if((!isForward())&&(the_sp.isForward())){
                        System.out.println("FEATLOC PRECEDES() MIX2");
                }
                return false;
	}

	public boolean contains(Span the_sp){
		if(the_sp==null){
			return false;
		}
		int min = getStart();
		int max = getEnd();
		if(min>max){
			int tmp = min;
			min = max;
			max = tmp;
		}
		if((the_sp.getStart()>=min)
				&&(the_sp.getStart()<=max)
				&&(the_sp.getEnd()>=min)
				&&(the_sp.getEnd()<=max)){
			return true;
		}
		return false;
	}

	public void Display(int the_depth){
		String offsetTxt = "";
		for(int i=0;i<the_depth;i++){
			offsetTxt += "\t";
		}
		System.out.println(offsetTxt+" Span <"+toString()+">");
	}
}


