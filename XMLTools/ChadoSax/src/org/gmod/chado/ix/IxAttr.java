package org.gmod.chado.ix;

import java.util.*;
import java.io.*;

/**

IxAttr - Attribute object for chado features

*/

public class IxAttr extends IxBase {

  public IxAttr(IxReadSax handler, String[] keyvals)
  {
    super(handler, keyvals);
  }

  public void setattr( Object val) {
    this.put("attr",val);
  }

  public Object getattr() {
    return this.get("attr");
  }

  public int printObj(PrintStream out, int depth) 
  {  
    int ln= 10;
    String tab= tab(depth); 
    Set keyset= this.keySet();
    boolean dobrak= keyset.size()>2;
    
    String tag = (String)this.get("tag");
    Object attr= this.get("attr");
    Object[] kv= id2name( tag,attr);
    tag= (String)kv[0]; attr= kv[1];
    
    out.print( tag+"=");  ln += tag.length()+1;
    if (dobrak) out.print( "{ " );
   
    if (attr instanceof IxBase) { //? IxObject
      ln += ((IxBase)attr).printObj(out,depth);
      }
    else {  
      attr= printable(attr);
      out.print(attr);  
      if (attr instanceof String) ln += ((String)attr).length(); 
      }

    for (Iterator i= keyset.iterator(); i.hasNext(); ) {
      String key= (String) i.next();
      if ("tag".equals(key)) continue;
      if ("attr".equals(key)) continue;

      Object val= this.get(key);
      kv= id2name(key,val);
      key= (String)kv[0]; val= kv[1];

      out.print(", ");
      out.print(key+"="); if (key!=null) ln += key.length() + 4;
      ln += printOneVal(out,depth,val);
      }
      
    if ( dobrak )  out.print(" } "); else  out.print(" ");  ln += 2;
    //$self->{handler}->{linelen} += $ln; #?
    return ln;
  }


}