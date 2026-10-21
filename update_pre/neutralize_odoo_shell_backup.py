#------------------------------
# INSTALAR ADDONS
#------------------------------
modules = [
    'web_company_color',
    'web_environment_ribbon',
]

mods = env['ir.module.module'].search([('name', 'in', modules)])
for m in mods:
    if m.state != 'installed':
        m.button_immediate_install()

#------------------------------
# CONFIGURAR COLORES NAVBAR Y NOMBRE DEL AVISO TEST
# -----------------------------
company = env.company
company.write({
    'color_navbar_bg': '#FF9900',
    'color_navbar_bg_hover': '#FF5E00',
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
# -----------------------------
company.write({
    'sii_enabled': False,
    'awci_webservice_apikey': 'fake',
})

# -----------------------------
# COMMIT FINAL
# -----------------------------
env.cr.commit()
print("Neutralización completada")