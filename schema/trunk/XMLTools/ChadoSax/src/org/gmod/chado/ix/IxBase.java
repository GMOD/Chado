package org.gmod.chado.ix;

import java.util.*;
import java.io.*;

/**

IxBase - Base object for chado features
See also org::gmod::chado::ix::IxBase perl module

Implements (a) hash of single value fields (tag==class,id,name,..)
Always has "tag" == classname and "id" == object id
Subclasses implement lists of other objects (multiple for same key)

Main change from Frank Smutniak's ChadoSaxReader/GenFeat source
is that specific fields are not defined, but accessed from HashMap of
fields, or ArrayList of multi-value fields.

E.g. getId() => get("id");
     setId("1") => put("id","1");
     getUniqueName() => get("uniquename");
     
Special case objects are
  IxFeat - keeps lists of subclass features, attributes, spans
  IxAttr - attribute-only object (essentially same as a field in main hash)
  IxSpan - feature location (start,stop,source_id)
     
*/

public class IxBase extends HashMap 
  implements IxObject  
{

  static String[] namelist= {
  "name","uniquename","cvname","program","accession","dbname"
   }; 
  
  IxReadSax handler;
  
  public IxBase(IxReadSax handler, String[] keyvals)
  {
    this.handler= handler; 
    // or use keyvals to old handler => object
    for (int i= 0; i<keyvals.length; i += 2) {
      put( keyvals[i], keyvals[i+1] );
      }
    if (!containsKey("tag")) put("tag","obj"); //?IxBase
  }
  
  /// just use HashMap methods ...
//  public void set(String key, Object val) {
//    this.put(key,val);
//  }
  
//  public Object get(String key) {
//    return this.get(key);
//  }

//  public Iterator keySet() {
//    return this.keySet().iterator();
//  }
  
  /**
    String getId() - the 'id' attribute of this object; 
    may be null though current Chado XML
      objects at this level all have id attributes
  */
  public String getId() { return (String)get("id"); }
  
  /**
    String getTag() - the 'class' of this object, from XML tag/element name
  */
  public String getTag() { return (String)get("tag"); }
  
  /**
  
    String getName() - tries to find in object fields best field for name,
      from list defined for Chado XML (name, uniqname, cvname, program, ..)
  
  */
  public String getName() {
    Object v;
    for (int i=0; i<namelist.length; i++) {
      v= get(namelist[i]);
      if (v instanceof String) return (String)v;
      }
    v= get("attr");
    if (v instanceof IxObject) {
      v= ((IxObject)v).getName();
      if (v instanceof String) return (String)v;
      }
    return (String) get("id");
  }
  
  public static boolean wantFullString= false;

  /**
    toString() - common Java object method; 
    -- now just tag:id of object
    -- with optional public static boolean wantFullString = true, will
    list all contents in result as does printObj()
    
  */
  public String toString() {
    // add all hash vals? == print
    if (wantFullString) {
      ByteArrayOutputStream os= new ByteArrayOutputStream();
      PrintStream out= new PrintStream(os);
      printObj( out,0);
      out.flush();
      return os.toString();
      }
    return getTag()+":"+getId();
    }

     
  public Object[] id2name(String key,Object val) {
    if (handler!=null && key.endsWith("_id") && val instanceof String) {
      IxObject ft= handler.getById((String)val);
      if (ft!=null) {
        String nm= ft.getName();
        if (nm!=null) {
          val= nm;
          key= key.substring(0,key.length()-3)+"_name";
          }
        }
      }
    return new Object[] { key, val };
  }
 
  protected Object printable(Object v) 
  {
    if (v instanceof String) {
      String s= (String) v;
//      my $m= tr/[({/[({/;
//      my $n= tr/])}/])}/;
//      if ($m != $n) {
//        s,[\[\]\(\)\{\}],.,g; #? may not need, but unbalanced for some [](){} symbols
//        }
      s= s.replace('\n',' ').replace('\r',' ');
      if (s.indexOf(' ')>0) return "'"+s+"'"; // check for '"
      else return s;
      }
    return v;
  }
   
  protected final String tab(int n) { 
    StringBuffer sb= new StringBuffer(2*n);
    for ( ; n>0; n--) sb.append("  "); return sb.toString(); 
    }

  protected int printOneVal(PrintStream out, int depth, Object val) 
  {
    int ln= 0;
    if (val instanceof IxBase) { //? IxObject
      ln += ((IxBase)val).printObj(out,depth);
      }
    else {  
      val= printable(val);
      out.print(val);  
      if (val instanceof String) ln += ((String)val).length(); 
      else ln += 10; //?
      }
    return ln;
  }
   
  /**
    printObj(PrintStream out, int tabbingDepth) 
    -- basic output of object data (HashMap fields) including nested objects    
  */
  public int printObj(PrintStream out, int depth) 
  {  
    int linewidth= 0;
    String tab= tab(depth); 
    out.print( tab + get("tag") +" = {\n");
    
    tab= tab(++depth);
    if (get("id")!=null) out.print( tab+"id="+get("id")+"\n") ;
    
    for (Iterator i= this.keySet().iterator(); i.hasNext(); ) {
      String key= (String) i.next();
      
      if ("tag".equals(key)) continue;
      if ("id".equals(key)) continue;
      if ("uniquename".equals(key) && this.containsKey("name")) continue;
      
      Object val= this.get(key);
      Object[] kv= id2name(key,val);
      key= (String)kv[0]; val= kv[1];
  
      out.print( tab+key);
      if (val == null) continue; //.length()==0)  next unless($v =~ /\S/);
      out.print( "=");
      printOneVal(out,depth,val);
      out.print( "\n");
      }
      
    return linewidth;
  }
    
    
  public String join(String del, Object[] a) {
    // utility
    StringBuffer sb= new StringBuffer();
    for (int i= 0; i<a.length; i++) {
      if (i>0) sb.append(del);
      sb.append(a[i]);
      }
     return sb.toString();
    }
    
}
