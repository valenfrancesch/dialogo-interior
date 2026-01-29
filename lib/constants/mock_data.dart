// Mock data for development/testing
// Replace with real Firebase data in production

const String mockPassage = "Juan 3:16-21";

const String mockEvangelioText =
    "Porque de tal manera amó Dios al mundo, que ha dado a su Hijo unigénito, "
    "para que todo aquel que en él cree, no se pierda, mas tenga vida eterna. "
    "Porque no envió Dios a su Hijo al mundo para condenar al mundo, sino para "
    "que el mundo sea salvo por él. El que en él cree, no es condenado; pero el "
    "que no cree, ya ha sido condenado, porque no ha creído en el nombre del "
    "unigénito Hijo de Dios.";

const String mockCatenaiAureaText =
    "Santo Tomás de Aquino: 'Dios amó al mundo con un amor tan perfecto que dio "
    "lo más precioso que tenía: su Hijo unigénito. Este amor no es condenación "
    "sino salvación, no es juicio sino redención.'\n\n"
    "San Juan Crisóstomo: 'El versículo expresa de manera clara la razón por la "
    "cual Dios nos envió a su Hijo: no para juzgar, sino para salvar.'";

const String mockBriefComment =
    "La fe en Cristo nos libera de la condenación y nos abre el camino hacia la "
    "vida eterna. No es un Dios de castigo, sino de amor infinito que ofrece "
    "redención a toda la humanidad.";

const String mockMemoryVerse = "Porque de tal manera amó Dios al mundo...";

// ===== DATOS MOCK PARA LA BIBLIOTECA =====

// Reflexiones del diario
const List<Map<String, dynamic>> mockDiaryEntries = [
  {
    'id': '1',
    'date': '27 de Enero, 2026',
    'passage': 'Mateo 5:1-12',
    'title': 'Las Bienaventuranzas',
    'excerpt':
        'Hoy reflexionaba sobre cómo Jesús nos invita a ser bienaventurados no por nuestros logros, sino por nuestra fe y entrega.',
    'reflection':
        'Las bienaventuranzas me enseñan que la verdadera felicidad no viene de lo material, sino de alinearnos con los valores del Reino de Dios. Ser pobre de espíritu, llorar, ser manso... estas aparentes debilidades son fortalezas en Dios.',
    'tags': ['Gratitud', 'Esperanza'],
  },
  {
    'id': '2',
    'date': '26 de Enero, 2026',
    'passage': 'Juan 14:27',
    'title': 'La Paz que Trasciende',
    'excerpt':
        'Encontré profunda paz en estas palabras. La paz de Cristo no es como la del mundo, es una paz interior que permanece.',
    'reflection':
        'En medio de las turbulencias de la vida, Cristo nos ofrece una paz que trasciende todo entendimiento. No es la ausencia de problemas, sino la presencia de su amor en nuestro corazón.',
    'tags': ['Paz', 'Esperanza'],
  },
  {
    'id': '3',
    'date': '25 de Enero, 2026',
    'passage': 'Filipenses 4:4-7',
    'title': 'Regocíjate y Ora',
    'excerpt':
        'La alegría y la oración van de la mano. Descubrí cómo la gratitud en la oración trae paz a mi corazón.',
    'reflection':
        'Cuando nos regocijamos y presentamos peticiones a Dios con acción de gracias, experimentamos la paz de Dios que sobrepasa todo entendimiento.',
    'tags': ['Gratitud', 'Paciencia'],
  },
];

// Etiquetas disponibles
const List<String> mockAllTags = [
  'Gratitud',
  'Esperanza',
  'Paciencia',
  'Perdón',
  'Familia',
  'Paz',
  'Amor',
  'Fe',
  'Confianza',
];

// Días con reflexiones guardadas
const List<int> mockDaysWithEntries = [1, 2, 3, 4, 5, 8, 12, 15, 20, 27];

// Estadísticas
const Map<String, dynamic> mockStats = {
  'streak': 12,
  'totalEntries': 48,
  'strealGrowth': '+2%',
  'lastEntry': '27 de Enero, 2026',
};

// ===== DATOS MOCK PARA FLASHBACK ESPIRITUAL =====

// Entradas del Timeline de Flashback
const List<Map<String, dynamic>> mockTimelineEntries = [
  {
    'yearsAgo': 1,
    'date': 'Dic 12, 2023',
    'passage': 'Juan 3:16-21',
    'summary':
        'Reflexioné sobre el amor infinito de Dios y cómo la fe en Cristo nos libera de la condenación.',
    'fullReflection':
        'Hoy entendí más profundamente que Dios no nos envía condenación sino salvación. Su amor es tan grande que dio lo más precioso. Me maravilla cómo en un año mi fe ha crecido en esta verdad.',
    'wordCount': 145,
    'isFirstReflection': false,
  },
  {
    'yearsAgo': 3,
    'date': 'Dic 12, 2021',
    'passage': 'Juan 3:16-21',
    'summary':
        'Primera vez reflexionando sobre este pasaje. Descubrí la profundidad del amor de Dios.',
    'fullReflection':
        'Esta es la primera vez que realmente me detengo en Juan 3:16. Siempre lo conocía, pero hoy entiendo que Dios ama al mundo de tal manera. Me impacta pensar que su amor es tan grande que no quiere condenación para nadie, sino salvación.',
    'wordCount': 89,
    'isFirstReflection': true,
  },
];

// Datos del crecimiento espiritual
const Map<String, dynamic> mockSpiritualGrowth = {
  'totalReflectionsOnPassage': 3,
  'yearsTracking': 3,
  'recurringThemes': ['Divine Timing', 'God\'s Love', 'Redemption'],
  'totalWordsWritten': 234,
  'emotionalProgression': 'Crecimiento en fe y confianza',
};

// Imagen destacada para la tarjeta de liturgia (simulado como URL)
const String mockLiturgyImageUrl =
    'https://images.unsplash.com/photo-1549289349-3c34ff87c4a2?w=400&h=300&fit=crop';
