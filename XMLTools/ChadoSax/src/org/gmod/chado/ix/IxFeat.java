package org.gmod.chado.ix;

import java.util.*;
import java.io.*;

/**

IxFeat - Feature object for chado features
See also org::gmod::parse::chado::IxBase perl module

  org::gmod::parse::chado::IxFeat; - 'feature' record contains
       (a) hash of single value fields (tag==class,id,name,..)
       (b) list of child sub-features
       (c) list of attributes (IxAttr)
       (d) list of feature locations (IxSpan)

*/

public class IxFeat extends IxBase  {


/** head1 METHODS

=head2 add
  
  add(IxFeat) - add child sub-feature record to list
  
*/

  ArrayList list, attrlist, loclist;  
  HashMap locsrc= null;

  public IxFeat(IxReadSax handler, String[] keyvals)
  {
    super(handler, keyvals);
  }

  public void add(IxFeat val) {
    if (list==null) list= new ArrayList();
    list.add(val);
  }

/** head2 getfeats([classTypes])
  
  return list of child sub-feature  
  classTypes - optional list of feature types to return
  
*/

  public IxFeat[] getfeats() { return getfeats(null); }
  public IxFeat[] getfeats(String[] types) {
    if (list==null) return null;
    int n= list.size();
    if (types==null) return (IxFeat[])list.toArray(new IxFeat[n]);
    else {
      ArrayList vals = new ArrayList(n);
      List typel= Arrays.asList(types);
      for (int i=0 ; i<n; i++) {
        IxFeat ft= (IxFeat)list.get(i);
        if (typel.contains(ft.get("tag")))
          vals.add(ft);
        }
      return (IxFeat[])vals.toArray((new IxFeat[vals.size()]));
      }
  }



/** head2 getfeattypes
  
  getfeattypes() - return list of child sub-feature field types
  note: want an iterator class to handle multiple methods per feature ?
  
*/

  public String[] getfeattypes() {
    if (list==null) return null;
    int n= list.size();
    ArrayList types= new ArrayList(n);
    for (int i= 0; i<n; i++) {
      IxFeat ft= (IxFeat)list.get(i);
      types.add((String)ft.get("tag"));
      }
    return (String[])types.toArray(new String[n]);
  }
  

/** head2 addattr

  addattr(IxAttr) - add IxAttr to list

*/
  
  public void addattr(IxAttr val) {
    if (attrlist==null) attrlist= new ArrayList();
    attrlist.add(val);
  }

/** head2 getattrs()

  get IxAttr list

*/
  
  public IxAttr[] getattrs() {
    if (attrlist==null) return null;
    return (IxAttr[])attrlist.toArray(new IxAttr[attrlist.size()]);
  }



/** head2 addloc(IxSpan)

  add IxSpan(nbeg,nend,src)

*/
  
  public void addloc(IxSpan val) {
    if (loclist==null) loclist= new ArrayList();
    loclist.add(val); locsrc= null;
  }

/** head2 getlocs()

  return hash by source id of ordered Spans
   make private? see getlocSource() ; getloc(source)
*/
  
  public HashMap getlocs() {
    if (loclist==null) return null;
    if (locsrc!=null) return locsrc; // have valid map of list
    
    locsrc= new HashMap();
    Object[] cs= loclist.toArray();
    for (int i=0; i<cs.length; i++) {
      IxSpan p= (IxSpan)cs[i];
      String src= (String) p.get("src");
      if (src==null) src=""; // can do null
      ArrayList al= (ArrayList)locsrc.get(src);
      if (al==null) {
        al= new ArrayList();
        locsrc.put(src,al);
        } 
      al.add(p);
      }
      
    for (Iterator i= locsrc.keySet().iterator(); i.hasNext(); ) {
      String src= (String) i.next();
      ArrayList al= (ArrayList) locsrc.get(src);
      Object[] ar= al.toArray();
      Arrays.sort(ar);
      //List sl= Arrays.asList(ar); //= funky list
      ArrayList sl= new ArrayList(Arrays.asList(ar)); // need for remove
      for (int k= sl.size()-1; k>0; k--) {
        if (sl.get(k).equals(sl.get(k-1))) sl.remove(k);
        }
      locsrc.put(src, sl);
      }
      
    return locsrc; 
  }
  
  public String[] getlocSources() {
    HashMap hloc= getlocs();
    if (hloc==null) return null;
    else {
      int n= hloc.keySet().size();
      return (String[]) hloc.keySet().toArray(new String[n]);
      }
  }
    
  public IxSpan[] getlocs(String source) {
    HashMap hloc= getlocs();
    if (hloc==null) return null;
    else {
      ArrayList al= (ArrayList) hloc.get(source);
      if (al==null) return null; //return al;
      return (IxSpan[]) al.toArray(new IxSpan[al.size()]);
      }
  }
  

  public int printObj(PrintStream out, int depth) {  
  
    int linewidth= super.printObj(out, depth);
    
    String tab= tab(++depth); 
      
     // ## need to order spans; check on source_id to see if all are same?
    HashMap hloc= getlocs();
    if ( hloc != null ) {
      for (Iterator li= hloc.keySet().iterator(); li.hasNext(); ) {
        String src=  (String)li.next();
        List al= (List) hloc.get(src);
        if (al==null || al.isEmpty()) continue; 
        out.print( tab+"loc."+src+"="+
          join(",",al.toArray()) + "\n");
        }
      }
    
    IxAttr[] attrs= getattrs();
    if ( attrs != null ) {
      int nd= 0; int ln= depth*2;
      //! $self->{handler}->{linelen}=0;
      for (int i= 0; i<attrs.length; i++) {
        if (i==0) out.print(tab);
        else if (ln>80) {
          out.print( "\n"+tab); ln= depth*2; //$self->{handler}->{linelen}=0; 
          }
        ln += attrs[i].printObj(out,depth); nd++;
        }   
      if (nd>0) out.print( "\n"); 
      }
    
    IxFeat[] fts= getfeats();
    if ( fts != null ) {
      for (int i= 0; i<fts.length; i++) {
        fts[i].printObj(out,depth);  
        }
      }
      
    out.print( tab+"}\n");
    return linewidth;
  }


}

