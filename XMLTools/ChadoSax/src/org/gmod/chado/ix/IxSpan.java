package org.gmod.chado.ix;

import java.util.*;
import java.io.*;

import org.gmod.chado.ix.Debug;


/**

IxSpan - Feature location object for chado features

*/

public class IxSpan extends IxBase
  implements Comparable
{

  int fmin=-1, fmax=-1, strand;
  
  public IxSpan(IxReadSax handler, String[] keyvals)
  {
    super(handler, keyvals);
  }

  public int compareTo(Object o) { //Comparable
    if (o instanceof IxSpan) {
      IxSpan co= (IxSpan)o;
      //swap(); co.swap();
      return (fmin - co.fmin);
      }
    return -1;
    }
    
  public boolean equals(Object o) { //Comparable
    if (o instanceof IxSpan) {
      IxSpan co= (IxSpan)o;
      //swap(); co.swap();
      return (fmin == co.fmin 
        && fmax == co.fmax 
        && strand == co.strand
        //&& get("src").equals(co.get("src"))//can be null
        );
      }
    return false;
    }
    
  public boolean reversed() { return (strand()<0); } // fmin > fmax
  public final boolean isForward() {  return !reversed(); }
  
  public int strand() { return strand; }
  public int fmin() {  return fmin; }
  public int fmax() { return fmax; }
  
  public Object put(Object k, Object v) {
    Object old= super.put(k,v);
    try {
      String s= (String)v;
           if ("nbeg".equals(k) || "fmin".equals(k) || "min".equals(k)) 
        fmin= Integer.parseInt(s); 
      else if ("nend".equals(k) || "fmax".equals(k) || "max".equals(k)) 
        fmax= Integer.parseInt(s); 
      else if ("strand".equals(k)) 
        strand= Integer.parseInt(s); 
      } catch (Exception e) { 
        Debug.errprintln(e.getMessage()+" : IxSpan "+k+"="+v); 
        }
    if (fmin>=0 && fmax>=0) swap(); // cant do till read both
    return old;
    }
 
  private final void swap() {
    if (fmin > fmax) { strand= -1; int f= fmin; fmin= fmax; fmax= f; }
    }
    
  public int length() {
    //if (fmin > fmax) return fmin - fmax + 1; else 
    return fmax - fmin + 1; 
    }

  public String toString() {
    return String.valueOf(fmin) + ".." + String.valueOf(fmax) ;
    }

}
