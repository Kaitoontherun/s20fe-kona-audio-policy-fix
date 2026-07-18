MODID=audio-fix-s20fe
AUTOMOUNT=true
PROPFILE=true
POSTFSDATA=true
LATESTARTSERVICE=false

print_modname() {
  ui_print "*******************************"
  ui_print "  Audio Fix S20 FE            "
  ui_print "  Bypass Broken Codec IC      "
  ui_print "*******************************"
}

REPLACE="
"

set_permissions() {
  set_perm_recursive  $MODPATH  0  0  0755  0644
}
