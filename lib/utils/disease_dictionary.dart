class DiseaseDictionary {
  // Las 21 condiciones + 1 Sano, estructuradas para PetScanIA
  static final Map<String, Map<String, dynamic>> _data = {
    // 🔴 ALERTA ROJA (Graves/Crónicas) - URGENCIA ALTA
    "Neoplasm": {
      "nombre": "Neoplasia / Tumores",
      "urgencia": "ALTA",
      "descripcion": "Crecimiento anormal de tejido que puede ser benigno o maligno (cáncer). Requiere biopsia y evaluación veterinaria urgente.",
      "recomendaciones": ["No presionar ni manipular el bulto.", "Agendar cita veterinaria urgente para biopsia.", "Evitar que la mascota se lama o muerda la zona."]
    },
    "Autoimmune Dermatosis": {
      "nombre": "Dermatosis Autoinmune",
      "urgencia": "ALTA",
      "descripcion": "El sistema inmunológico ataca la propia piel de la mascota, causando úlceras, costras y pérdida de pigmentación.",
      "recomendaciones": ["Evitar exposición directa al sol.", "Mantener la piel limpia para evitar infecciones secundarias.", "Requiere tratamiento inmunosupresor veterinario."]
    },
    "Pemphigus": {
      "nombre": "Pénfigo",
      "urgencia": "ALTA",
      "descripcion": "Enfermedad autoinmune grave que causa ampollas y costras severas, comúnmente en la cara, orejas y patas.",
      "recomendaciones": ["Acudir al veterinario inmediatamente.", "No reventar las ampollas ni arrancar costras.", "Mantener al animal en un ambiente limpio y sin estrés."]
    },

    // 🦠 PARASITARIAS (Muy Comunes) - URGENCIA MEDIA
    "Sarcoptic Mange": {
      "nombre": "Sarna Sarcóptica",
      "urgencia": "MEDIA",
      "descripcion": "Infección por ácaros altamente contagiosa (incluso a humanos). Causa picazón extrema, costras y pérdida de pelo.",
      "recomendaciones": ["Aislar a la mascota de otros animales y personas.", "Lavar su cama y juguetes con agua caliente.", "Acudir al veterinario para tratamiento acaricida."]
    },
    "Demodectic Mange": {
      "nombre": "Sarna Demodécica",
      "urgencia": "MEDIA",
      "descripcion": "Causada por ácaros que viven naturalmente en la piel, pero proliferan si el sistema inmune baja. Causa calvas sin tanta picazón.",
      "recomendaciones": ["Mejorar la dieta para fortalecer el sistema inmune.", "Evitar el estrés en la mascota.", "Consultar al veterinario para tratamiento específico."]
    },
    "Ear Mite": {
      "nombre": "Ácaros en el oído",
      "urgencia": "MEDIA",
      "descripcion": "Ácaros que infestan el canal auditivo. Causa secreción oscura similar a posos de café y mucha picazón.",
      "recomendaciones": ["Limpiar suavemente la parte externa de la oreja con gasa.", "No introducir hisopos en el canal auditivo.", "Requiere gotas acaricidas recetadas."]
    },
    "Flea Dermatitis": {
      "nombre": "Dermatitis por pulgas",
      "urgencia": "MEDIA",
      "descripcion": "Reacción alérgica severa a la saliva de la pulga. Causa pérdida de pelo y costras, especialmente en la base de la cola.",
      "recomendaciones": ["Aplicar tratamiento antipulgas recomendado por el vet.", "Limpiar y aspirar exhaustivamente la casa y camas.", "Baño calmante con avena para aliviar el picor."]
    },
    "Tick Dermatitis": {
      "nombre": "Dermatitis por garrapatas",
      "urgencia": "MEDIA",
      "descripcion": "Inflamación o infección localizada en la zona donde se adhirió una garrapata.",
      "recomendaciones": ["Revisar cuidadosamente el resto del cuerpo.", "Desinfectar la zona de la picadura con clorhexidina.", "Observar síntomas de letargo o fiebre (enfermedades transmitidas por garrapatas)."]
    },
    "Cheyletiella Dermatitis": {
      "nombre": "Caspa Andante",
      "urgencia": "MEDIA",
      "descripcion": "Ácaros grandes que se ven como escamas de caspa moviéndose sobre el pelaje. Es contagioso.",
      "recomendaciones": ["Aislar de otras mascotas.", "Lavar todos los accesorios del animal.", "Visitar al veterinario para un antiparasitario adecuado."]
    },

    // 🍄 INFECCIOSAS Y FÚNGICAS - URGENCIA MEDIA
    "Ringworm": {
      "nombre": "Tiña (Hongo)",
      "urgencia": "MEDIA",
      "descripcion": "Infección por hongos altamente contagiosa que forma lesiones circulares sin pelo.",
      "recomendaciones": ["Usar guantes al manipular a la mascota (es contagioso a humanos).", "Aislar a la mascota temporalmente.", "Limpiar el ambiente con desinfectantes fungicidas."]
    },
    "Fungal Infection": {
      "nombre": "Infección por otros hongos",
      "urgencia": "MEDIA",
      "descripcion": "Crecimiento excesivo de levaduras u hongos, causando piel engrasada, mal olor y picazón.",
      "recomendaciones": ["Mantener la piel y pliegues secos.", "Evitar bañar a la mascota en exceso sin champú medicado.", "Acudir al vet para tratamiento antifúngico."]
    },
    "Pyoderma": {
      "nombre": "Infección bacteriana (Pioderma)",
      "urgencia": "MEDIA",
      "descripcion": "Infección bacteriana en la piel que produce granos, pústulas con pus y costras.",
      "recomendaciones": ["Limpiar suavemente con jabón antiséptico para mascotas.", "No exprimir las pústulas.", "Probablemente requiera antibióticos orales recetados."]
    },
    "Hot Spot": {
      "nombre": "Parche caliente infectado",
      "urgencia": "MEDIA",
      "descripcion": "Dermatitis húmeda aguda. Lesión roja, húmeda, caliente y muy dolorosa que aparece repentinamente.",
      "recomendaciones": ["Recortar el pelo alrededor de la lesión para que ventile.", "Limpiar con clorhexidina o povidona yodada diluida.", "Evitar que la mascota se lama (usar collar isabelino)."]
    },

    // 🔥 ALERGIAS E INFLAMATORIAS - URGENCIA BAJA/MEDIA
    "Atopy": {
      "nombre": "Dermatitis Atópica",
      "urgencia": "BAJA",
      "descripcion": "Alergia ambiental (polen, ácaros del polvo). Causa enrojecimiento y picazón crónica en patas, cara y vientre.",
      "recomendaciones": ["Limpiar las patas con toallitas húmedas después de pasear.", "Lavar su cama con agua caliente frecuentemente.", "Consultar al vet para manejo de alergias a largo plazo."]
    },
    "Contact Dermatitis": {
      "nombre": "Dermatitis por contacto",
      "urgencia": "BAJA",
      "descripcion": "Reacción alérgica por tocar irritantes (plásticos, productos de limpieza, plantas).",
      "recomendaciones": ["Lavar la zona afectada con agua tibia para retirar el irritante.", "Identificar y retirar la causa (cambiar platos, alfombras, etc.).", "Aplicar aloe vera puro o cremas calmantes para mascotas."]
    },
    "Flea Allergy": {
      "nombre": "Alergia a pulgas",
      "urgencia": "BAJA",
      "descripcion": "Hipersensibilidad a la picadura. Una sola pulga desencadena mucha picazón.",
      "recomendaciones": ["Mantener control preventivo de pulgas estricto todo el año.", "Revisar con peine antipulgas regularmente.", "Bañar con champú calmante."]
    },
    "Skin Allergy": {
      "nombre": "Alergia cutánea general",
      "urgencia": "BAJA",
      "descripcion": "Reacción alérgica inespecífica que inflama la piel.",
      "recomendaciones": ["Evaluar posibles cambios recientes en dieta o ambiente.", "Dar suplementos de Omega 3 para fortalecer la barrera cutánea.", "Vigilar que no se haga heridas al rascarse."]
    },
    "Seborrhea": {
      "nombre": "Seborrea",
      "urgencia": "BAJA",
      "descripcion": "Trastorno de la queratinización. La piel puede volverse muy seca (caspa) o muy grasosa y maloliente.",
      "recomendaciones": ["Bañar con champú antiseborreico recomendado por el vet.", "Cepillar diariamente para distribuir los aceites naturales.", "Proporcionar dieta rica en ácidos grasos."]
    },

    // ⚠️ CONDICIONES ESPECÍFICAS - URGENCIA BAJA
    "Alopecia": {
      "nombre": "Pérdida de pelo (Alopecia)",
      "urgencia": "BAJA",
      "descripcion": "Caída anormal de pelo. Puede ser hormonal, parasitaria o por estrés.",
      "recomendaciones": ["Observar si hay otros síntomas como aumento de sed o peso.", "Asegurar una nutrición de alta calidad.", "Consultar al veterinario para análisis de sangre."]
    },
    "Lick Granuloma": {
      "nombre": "Granuloma por lamido",
      "urgencia": "BAJA",
      "descripcion": "Úlcera gruesa causada por el lamido compulsivo constante, generalmente en las patas delanteras, a menudo por estrés.",
      "recomendaciones": ["Aumentar el ejercicio y la estimulación mental de la mascota.", "Proteger la herida (vendas ligeras o collar isabelino).", "Identificar la fuente de ansiedad."]
    },
    "Puppy Strawberry": {
      "nombre": "Enfermedad de cachorros (Impétigo)",
      "urgencia": "BAJA",
      "descripcion": "Pequeñas ampollas con pus en el abdomen de los cachorros. Generalmente leve y autolimitada.",
      "recomendaciones": ["Limpiar el abdomen con un jabón suave antibacteriano.", "Mejorar las condiciones de higiene del entorno del cachorro.", "Si no mejora, buscar champú medicado veterinario."]
    },

    // ✅ SANO
    "Healthy": {
      "nombre": "Piel Saludable - Control",
      "urgencia": "NULA",
      "descripcion": "No se detectan anomalías patológicas visuales en el área analizada.",
      "recomendaciones": ["Mantener la rutina de cuidado, higiene y alimentación actual.", "Continuar con desparasitación regular.", "Dar mucho amor a tu mascota."]
    }
  };

  // Función inteligente BILINGÜE Y A PRUEBA DE BALAS 🧠
  static Map<String, dynamic> getInfo(String rawDiagnosis) {
    // 1. Limpiamos lo que manda Render (minúsculas, quitamos guiones bajos)
    String searchKey = rawDiagnosis.toLowerCase().replaceAll('_', ' ').trim();
    
    for (String key in _data.keys) {
      String keyLimpia = key.toLowerCase().replaceAll('_', ' ');
      String nombreEspanol = _data[key]!["nombre"].toLowerCase();
      
      // 2. Buscamos coincidencias cruzadas (Inglés o Español)
      // Si la API manda "Skin Allergy", "skin_allergy" o "alergia cutánea", lo va a encontrar.
      if (searchKey.contains(keyLimpia) || 
          searchKey.contains(nombreEspanol) ||
          nombreEspanol.contains(searchKey) ||
          keyLimpia.contains(searchKey)) {
        return _data[key]!; // Retorna toda la data en ESPAÑOL
      }
    }
    
    // Si la IA manda un texto que definitivamente no está en la lista de las 21
    return {
      "nombre": rawDiagnosis, // Mostramos lo que mandó la IA tal cual
      "urgencia": "MEDIA",
      "descripcion": "Anomalía detectada. (El servidor envió: $rawDiagnosis).",
      "recomendaciones": ["Mantener el área limpia.", "Agendar cita con el veterinario."]
    };
  }
}