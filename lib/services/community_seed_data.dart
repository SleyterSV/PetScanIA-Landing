import 'package:petscania/models/community_pet.dart';
import 'package:petscania/models/community_campaign.dart';

class CommunitySeedData {
  static const List<String> cities = [
    'Todas',
    'Lima',
    'Callao',
    'Arequipa',
    'Trujillo',
  ];

  static const List<String> species = ['Todos', 'Perro', 'Gato', 'Otro'];

  static const List<String> sizes = ['Todos', 'Pequeno', 'Mediano', 'Grande'];

  static const List<String> ages = [
    'Todos',
    'Cachorro',
    'Joven',
    'Adulto',
    'Senior',
  ];

  static const List<String> statuses = [
    'Todos',
    'Urgente',
    'Verificado',
    'Con seguimiento',
  ];

  static const List<PetCommunityPost> posts = [
    PetCommunityPost(
      id: 'adp-001',
      type: CommunityPostType.adoption,
      imageUrl:
          'https://images.unsplash.com/photo-1552053831-71594a27632d?auto=format&fit=crop&w=900&q=80',
      name: 'Luna',
      species: 'Perro',
      breed: 'Mestiza',
      age: 'Joven',
      size: 'Mediano',
      city: 'Lima',
      district: 'Santiago de Surco',
      description:
          'Muy carinosa, tranquila en casa y sociable con otros perros. Busca una familia paciente que le de paseos diarios.',
      healthStatus: 'Esterilizada y desparasitada',
      vaccines: 'Vacunas al dia',
      contactName: 'Refugio Patitas Surco',
      contactPhone: '+51987654321',
      location: 'Parque de la Amistad',
      dateLabel: 'Publicado hoy',
      status: 'Verificado',
      reward: '',
      distanceKm: 2.4,
      spreadCount: 48,
      verified: true,
    ),
    PetCommunityPost(
      id: 'adp-002',
      type: CommunityPostType.adoption,
      imageUrl:
          'https://images.unsplash.com/photo-1574158622682-e40e69881006?auto=format&fit=crop&w=900&q=80',
      name: 'Michi',
      species: 'Gato',
      breed: 'Criollo',
      age: 'Cachorro',
      size: 'Pequeno',
      city: 'Lima',
      district: 'Miraflores',
      description:
          'Curioso, jugueton y acostumbrado a arenero. Ideal para departamento con ventanas protegidas.',
      healthStatus: 'Desparasitado',
      vaccines: 'Primera vacuna',
      contactName: 'Andrea R.',
      contactPhone: '+51965432109',
      location: 'Av. Angamos',
      dateLabel: 'Hace 1 dia',
      status: 'Con seguimiento',
      reward: '',
      distanceKm: 3.1,
      spreadCount: 35,
      verified: true,
    ),
    PetCommunityPost(
      id: 'adp-003',
      type: CommunityPostType.adoption,
      imageUrl:
          'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?auto=format&fit=crop&w=900&q=80',
      name: 'Rocky',
      species: 'Perro',
      breed: 'Cruce Labrador',
      age: 'Adulto',
      size: 'Grande',
      city: 'Callao',
      district: 'La Punta',
      description:
          'Noble, protector y con mucha energia. Necesita una familia activa y espacio para caminar.',
      healthStatus: 'Evaluacion veterinaria reciente',
      vaccines: 'Refuerzo pendiente',
      contactName: 'Red Rescate Callao',
      contactPhone: '+51911222333',
      location: 'Malecon Pardo',
      dateLabel: 'Hace 3 dias',
      status: 'Verificado',
      reward: '',
      distanceKm: 8.6,
      spreadCount: 64,
      verified: true,
    ),
    PetCommunityPost(
      id: 'lost-001',
      type: CommunityPostType.lost,
      imageUrl:
          'https://images.unsplash.com/photo-1583337130417-3346a1be7dee?auto=format&fit=crop&w=900&q=80',
      name: 'Toby',
      species: 'Perro',
      breed: 'Shih Tzu',
      age: 'Adulto',
      size: 'Pequeno',
      city: 'Lima',
      district: 'San Miguel',
      description:
          'Usa collar azul, responde a su nombre y puede estar asustado. Su familia lo busca desde la tarde.',
      healthStatus: 'Necesita medicamento diario',
      vaccines: 'Vacunas al dia',
      contactName: 'Marcos P.',
      contactPhone: '+51999888777',
      location: 'Ultima vez visto cerca a Plaza San Miguel',
      dateLabel: 'Hoy, 5:40 p.m.',
      status: 'Urgente',
      reward: 'S/ 300',
      distanceKm: 1.7,
      spreadCount: 132,
      verified: true,
    ),
    PetCommunityPost(
      id: 'lost-002',
      type: CommunityPostType.lost,
      imageUrl:
          'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?auto=format&fit=crop&w=900&q=80',
      name: 'Nina',
      species: 'Gato',
      breed: 'Atigrada',
      age: 'Joven',
      size: 'Pequeno',
      city: 'Lima',
      district: 'Barranco',
      description:
          'Gatita atigrada de ojos verdes. Es timida y suele esconderse en cocheras o jardines.',
      healthStatus: 'Esterilizada',
      vaccines: 'Sin dato',
      contactName: 'Lucia V.',
      contactPhone: '+51933445566',
      location: 'Jr. Domeyer con San Martin',
      dateLabel: 'Ayer, 9:15 p.m.',
      status: 'Con seguimiento',
      reward: '',
      distanceKm: 5.2,
      spreadCount: 87,
      verified: false,
    ),
    PetCommunityPost(
      id: 'found-001',
      type: CommunityPostType.found,
      imageUrl:
          'https://images.unsplash.com/photo-1543466835-00a7907e9de1?auto=format&fit=crop&w=900&q=80',
      name: 'Sin nombre',
      species: 'Perro',
      breed: 'Beagle',
      age: 'Adulto',
      size: 'Mediano',
      city: 'Lima',
      district: 'Pueblo Libre',
      description:
          'Encontrado con collar rojo, muy docil. Esta resguardado temporalmente y se busca a su familia.',
      healthStatus: 'Se ve estable',
      vaccines: 'Sin dato',
      contactName: 'Daniela C.',
      contactPhone: '+51922334455',
      location: 'Parque Candamo',
      dateLabel: 'Hoy, 8:10 a.m.',
      status: 'Verificado',
      reward: '',
      distanceKm: 4.8,
      spreadCount: 56,
      verified: true,
    ),
    PetCommunityPost(
      id: 'found-002',
      type: CommunityPostType.found,
      imageUrl:
          'https://images.unsplash.com/photo-1495360010541-f48722b34f7d?auto=format&fit=crop&w=900&q=80',
      name: 'Gatito encontrado',
      species: 'Gato',
      breed: 'Blanco con gris',
      age: 'Cachorro',
      size: 'Pequeno',
      city: 'Arequipa',
      district: 'Yanahuara',
      description:
          'Aparecio cerca de una tienda. Tiene mucha hambre, pero permite acercarse con cuidado.',
      healthStatus: 'Pendiente revision',
      vaccines: 'Sin dato',
      contactName: 'Sofia M.',
      contactPhone: '+51977889900',
      location: 'Plaza de Yanahuara',
      dateLabel: 'Hace 2 dias',
      status: 'Urgente',
      reward: '',
      distanceKm: 12.3,
      spreadCount: 29,
      verified: false,
    ),
  ];

  static const List<HappyStory> happyStories = [
    HappyStory(
      id: 'story-001',
      title: 'Luna ya duerme en casa',
      imageUrl:
          'https://images.unsplash.com/photo-1601758125946-6ec2ef64daf8?auto=format&fit=crop&w=900&q=80',
      city: 'Lima',
      summary:
          'Despues de 6 dias compartiendo su alerta, Luna volvio con su familia gracias a una vecina de Surco.',
      impact: '184 personas ayudaron a difundir',
    ),
    HappyStory(
      id: 'story-002',
      title: 'Bruno encontro familia',
      imageUrl:
          'https://images.unsplash.com/photo-1596492784531-6e6eb5ea9993?auto=format&fit=crop&w=900&q=80',
      city: 'Callao',
      summary:
          'Un rescatista lo publico y una familia cercana completo la adopcion responsable en 48 horas.',
      impact: 'Adopcion verificada',
    ),
    HappyStory(
      id: 'story-003',
      title: 'Mia regreso por una foto',
      imageUrl:
          'https://images.unsplash.com/photo-1533738363-b7f9aef128ce?auto=format&fit=crop&w=900&q=80',
      city: 'Arequipa',
      summary:
          'El cartel automatico compartido por WhatsApp llego al grupo correcto del barrio.',
      impact: 'Cartel compartido 92 veces',
    ),
  ];

  static const List<CommunityCampaign> campaigns = [
    CommunityCampaign(
      id: 'camp-001',
      title: 'Vacunaton antirrabica gratuita',
      category: 'Vacunaton',
      city: 'Lima',
      district: 'San Miguel',
      location: 'Parque Media Luna',
      dateLabel: 'Sabado 4 de mayo · 9:00 a.m.',
      organizer: 'Municipalidad + PetScanIA',
      description:
          'Jornada gratuita para perros y gatos. Atencion por orden de llegada con equipo veterinario aliado.',
      requirements: 'DNI del responsable, correa o transportador.',
      imageUrl:
          'https://images.unsplash.com/photo-1576201836106-db1758fd1c97?auto=format&fit=crop&w=900&q=80',
      capacity: 240,
      reserved: 138,
      isVerified: true,
    ),
    CommunityCampaign(
      id: 'camp-002',
      title: 'Desparasitacion solidaria',
      category: 'Desparasitacion',
      city: 'Lima',
      district: 'Villa El Salvador',
      location: 'Losas deportivas Sector 3',
      dateLabel: 'Domingo 5 de mayo · 10:00 a.m.',
      organizer: 'Red de Rescatistas Sur',
      description:
          'Desparasitacion gratuita para mascotas de familias vulnerables y rescatistas independientes.',
      requirements: 'Mascota en ayunas 4 horas, peso aproximado.',
      imageUrl:
          'https://images.unsplash.com/photo-1601758125946-6ec2ef64daf8?auto=format&fit=crop&w=900&q=80',
      capacity: 180,
      reserved: 92,
      isVerified: true,
    ),
    CommunityCampaign(
      id: 'camp-003',
      title: 'Campana de esterilizacion a bajo costo',
      category: 'Esterilizacion',
      city: 'Callao',
      district: 'Bellavista',
      location: 'Clinica aliada Patitas Bellavista',
      dateLabel: 'Del 6 al 10 de mayo',
      organizer: 'Veterinarias aliadas',
      description:
          'Cupos subvencionados para controlar camadas no deseadas y apoyar adopciones responsables.',
      requirements: 'Reserva previa, ayuno y evaluacion basica.',
      imageUrl:
          'https://images.unsplash.com/photo-1628009368231-7bb7cfcb0def?auto=format&fit=crop&w=900&q=80',
      capacity: 80,
      reserved: 61,
      isVerified: true,
    ),
    CommunityCampaign(
      id: 'camp-004',
      title: 'Placas de identificacion gratis',
      category: 'Identificacion',
      city: 'Lima',
      district: 'Miraflores',
      location: 'Parque Kennedy',
      dateLabel: 'Viernes 3 de mayo · 4:00 p.m.',
      organizer: 'PetScanIA Comunidad',
      description:
          'Entrega de placas QR para reducir mascotas perdidas y acelerar reencuentros.',
      requirements: 'Nombre de mascota y telefono de contacto.',
      imageUrl:
          'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?auto=format&fit=crop&w=900&q=80',
      capacity: 120,
      reserved: 77,
      isVerified: true,
    ),
  ];

  static List<PetCommunityPost> postsByType(CommunityPostType type) {
    return posts.where((post) => post.type == type).toList();
  }
}
