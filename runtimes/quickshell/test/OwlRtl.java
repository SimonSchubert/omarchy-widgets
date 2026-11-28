// Whether owl.jar lays each file out right to left in each language: "<lang> <rtl> <file>" per line, for run.sh
// to hold Owl.js's program.rtl to. A file that doesn't compile is left out.
public class OwlRtl {
  public static void main(String[] args) throws Exception {
    String[] langs = { "en", "de", "ar", "fa", "he", "ur" };
    for (String f : args) {
      String src = new String(java.nio.file.Files.readAllBytes(java.nio.file.Paths.get(f)), "UTF-8");
      for (String lang : langs) {
        try {
          dev.omalauncher.widgets.lang.Program p = dev.omalauncher.widgets.lang.Compiler.Companion.compile(src, lang);
          System.out.println(lang + " " + p.getRtl() + " " + f);
        } catch (Exception e) { break; }
      }
    }
  }
}
