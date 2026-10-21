#------------------------------
# INSTALAR ADDONS
#------------------------------
modules = [
    'web_company_color',
    'web_environment_ribbon',
]

mods = env['ir.module.module'].search([('name', 'in', modules)])
missing = set(modules) - set(mods.mapped('name'))
if missing:
    print("AVISO: módulos no disponibles en el addons_path: %s" % ", ".join(sorted(missing)))
for m in mods:
    if m.state != 'installed':
        m.button_immediate_install()

#------------------------------
# CONFIGURAR COLORES NAVBAR Y NOMBRE DEL AVISO TEST
# -----------------------------
company = env.company

# Color de la navbar: vista heredada de web.layout guardada en BD.
# No depende de la versión de Odoo ni del módulo web_company_color
# (y al estar en BD no se propaga a Prod con el rsync de ./custom).
NAVBAR_BG = '#FF9900'
NAVBAR_BG_HOVER = '#FF5E00'
NAVBAR_KEY = 'neutralize.navbar_color'
navbar_arch = """<data>
  <xpath expr="//head" position="inside">
    <style>
      .o_main_navbar,
      .o_main_navbar .o_menu_sections .o_nav_entry,
      .o_main_navbar .o_menu_sections .dropdown-toggle { background-color: %s !important; }
      .o_main_navbar .o_menu_sections .o_nav_entry:hover,
      .o_main_navbar .o_menu_sections .dropdown-toggle:hover { background-color: %s !important; }
    </style>
  </xpath>
</data>""" % (NAVBAR_BG, NAVBAR_BG_HOVER)

View = env['ir.ui.view'].sudo()
navbar_view = View.search([('key', '=', NAVBAR_KEY)], limit=1)
if navbar_view:
    navbar_view.write({'arch_db': navbar_arch})
else:
    View.create({
        'name': 'Neutralize: navbar color',
        'key': NAVBAR_KEY,
        'type': 'qweb',
        'mode': 'extension',
        'inherit_id': env.ref('web.layout').id,
        'arch_db': navbar_arch,
    })

ribbon = env['ir.config_parameter'].sudo()
ribbon.set_param(
    'ribbon.name','PRE-PROD<br/>({db_name})'
)
# -----------------------------
# DESACTIVAR CRON (equivalente SQL pero correcto)
# -----------------------------
cron = env['ir.cron'].browse(35)
if cron.exists():
    cron.write({'active': False})

# -----------------------------
# DESACTIVAR SII / ANCORA
# (campos propios de CENTUM: solo se escriben si existen en esta instalación)
# -----------------------------
sii_vals = {}
if 'sii_enabled' in company._fields:
    sii_vals['sii_enabled'] = False
if 'awci_webservice_apikey' in company._fields:
    sii_vals['awci_webservice_apikey'] = 'fake'
if sii_vals:
    company.write(sii_vals)

# -----------------------------
# COMMIT FINAL
# -----------------------------
env.cr.commit()
print("Neutralización completada")