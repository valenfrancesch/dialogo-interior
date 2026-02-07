class AppData {
  static const String appGroupId = 'group.dialogo_interior'; // TODO: Replace with your actual App Group ID

  static const List<String> countries = [
    'Argentina', 'Bolivia', 'Chile', 'Colombia', 'Costa Rica', 
    'Ecuador', 'España', 'México', 'Paraguay', 'Perú', 'Uruguay', 'Otro'
  ];

  static const Map<String, List<String>> provinces = {
    'Argentina': [
      'CABA', 'Buenos Aires', 'Catamarca', 'Chaco', 'Chubut', 'Córdoba', 'Corrientes', 
      'Entre Ríos', 'Formosa', 'Jujuy', 'La Pampa', 'La Rioja', 'Mendoza', 'Misiones', 
      'Neuquén', 'Río Negro', 'Salta', 'San Juan', 'San Luis', 'Santa Cruz', 
      'Santa Fe', 'Santiago del Estero', 'Tierra del Fuego', 'Tucumán'
    ],
    'Uruguay': [
      'Artigas', 'Canelones', 'Cerro Largo', 'Colonia', 'Durazno', 'Flores', 'Florida', 
      'Lavalleja', 'Maldonado', 'Montevideo', 'Paysandú', 'Río Negro', 'Rivera', 
      'Rocha', 'Salto', 'San José', 'Soriano', 'Tacuarembó', 'Treinta y Tres'
    ],
    'Chile': [
      'Arica y Parinacota', 'Tarapacá', 'Antofagasta', 'Atacama', 'Coquimbo', 
      'Valparaíso', 'Metropolitana', 'O\'Higgins', 'Maule', 'Ñuble', 'Biobío', 
      'Araucanía', 'Los Ríos', 'Los Lagos', 'Aysén', 'Magallanes'
    ],
    'México': [
      'Aguascalientes', 'Baja California', 'Baja California Sur', 'Campeche', 'Chiapas', 
      'Chihuahua', 'CDMX', 'Coahuila', 'Colima', 'Durango', 'Guanajuato', 'Guerrero', 
      'Hidalgo', 'Jalisco', 'México', 'Michoacán', 'Morelos', 'Nayarit', 'Nuevo León', 
      'Oaxaca', 'Puebla', 'Querétaro', 'Quintana Roo', 'San Luis Potosí', 'Sinaloa', 
      'Sonora', 'Tabasco', 'Tamaulipas', 'Tlaxcala', 'Veracruz', 'Yucatán', 'Zacatecas'
    ],
  };

  /// Get provinces for a specific country
  static List<String> getProvincesForCountry(String country) {
    return provinces[country] ?? [];
  }
}
