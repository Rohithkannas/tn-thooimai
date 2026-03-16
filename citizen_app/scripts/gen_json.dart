import 'dart:convert';
import 'dart:io';

void main() {
  final Map<String, List<String>> wasteData = {
    'wet': ['coconut shell,தேங்காய் சிரட்டை,Thengai sirattai,Compostable,,', 'banana leaf,வாழை இலை,Vaazhai ilai,Compostable,,pongal', 'rice water,கழுநீர்,Kazhuneer,Drain or feed plants,,', 'vegetable peels,காய்கறி கழிவு,Kaaikari kazhivu,Compostable,,', 'tea bags,டீ தூள்,Tea thool,Compostable,,', 'flower garlands,பூ மாலை,Poo maalai,Compostable,,pongal', 'food leftovers,மீதமுள்ள உணவு,Meethamulla unavu,Compostable,,', 'eggshells,முட்டை ஓடு,Muttai Odu,Compostable,,', 'used cooking oil,பயன்படுத்திய எண்ணெய்,Payanpaduthiya yennai,Handover to collector,,', 'garden trimmings,தோட்ட கழிவு,Thotta kazhivu,Compostable,,', 'sugarcane pulp,கரும்பு சக்கை,Karumbu chakkai,Compostable,,pongal', 'tamarind shells,புளியம்பழ ஓடு,Puliyampazha odu,Compostable,,', 'mango peels,மாம்பழ தோல்,Maampazha thol,Compostable,,', 'jasmine garland,மல்லிகை பூ,Malligai poo,Compostable,,', 'curry leaves,கறிவேப்பிலை,Kariveppilai,Compostable,,', 'coffee grounds,காபி தூள்,Coffee thool,Compostable,,'],
    'dry': ['newspaper,பழைய செய்தித்தாள்,Pazhaya seithithaal,Recyclable,,', 'milk pouch,பால் கவர்,Paal cover,Wash and dry before disposal,,', 'glass bottle,கண்ணாடி பாட்டில்,Kannadi bottle,Recyclable,,', 'cardboard,அட்டைப் பெட்டி,Attai petti,Recyclable,,', 'aluminium foil,அலுமினிய ஃபாயில்,Aluminium foil,Recyclable,,', 'PET bottle,பிளாஸ்டிக் பாட்டில்,Plastic bottle,Crush before disposal,,', 'metal tin,டின்,Tin,Recyclable,,', 'cloth rags,பழைய துணி,Pazhaya thuni,Hand over dry,,', 'foam packaging,போம் கவர்,Foam cover,Non-recyclable,Often confused as recyclable,', 'rubber slipper,ரப்பர் செருப்பு,Rubber seruppu,Hand over to dry waste,,', 'tetrapak carton,டெட்ரா பேக்,Tetra pack,Flatten before disposal,,', 'plastic cover,பிளாஸ்டிக் பை,Plastic pai,Recyclable,,', 'steel scrap,இரும்பு கழிவு,Irumbu kazhivu,Recyclable,,', 'coconut shell dry,காய்ந்த தேங்காய் ஓடு,Kaintha thengai odu,Can be used as fuel,,', 'jute bag,சணல் பை,Sanal pai,Recyclable,,', 'magazine,பத்திரிகை,Pathirigai,Recyclable,,'],
    'hazardous': ['batteries,பேட்டரி,Battery,Handover carefully,,', 'tube light,டியூப் லைட்,Tube light,Wrap in paper to avoid breakage,,', 'paint can,பெயிண்ட் டப்பா,Paint dappa,Ensure empty before disposal,,', 'mosquito repellent,கொசு மருந்து,Kosu marunthu,Hazardous,,', 'expired medicine,காலாவதியான மருந்து,Kaalavathiyana marunthu,Handover separately,,', 'nail polish,நெயில் பாலிஷ்,Nail polish,Hazardous,,', 'hair dye,தலைமுடி சாயம்,Thalaimudi saayam,Hazardous,,', 'thermometer,தெர்மாமீட்டர்,Thermometer,Contains mercury,,', 'bleach bottle,பிளீச் பாட்டில்,Bleach bottle,Wash before disposal,,', 'phenyl bottle,பினாயில் பாட்டில்,Phenyl bottle,Hazardous,,', 'pesticide,பூச்சிக்கொல்லி,Poochikolli,Hazardous,,', 'car battery,கார் பேட்டரி,Car battery,Recycle properly,,', 'Aerosol can,ஸ்ப்ரே பாட்டில்,Spray bottle,Hazardous,,', 'glue,பசை,Pasai,Hazardous,,', 'sanitizer,சானிடைசர்,Sanitizer,Flammable,,', 'wood polish,மர பாலிஷ்,Mara polish,Hazardous,,'],
    'ewaste': ['mobile phone,மொபைல் போன்,Mobile phone,E-waste collection,,', 'charger,சார்ஜர்,Charger,E-waste collection,,', 'earphones,இயர்போன்,Earphones,E-waste collection,,', 'remote control,ரிமோட்,Remote,Remove batteries before disposal,,', 'calculator,கால்குலேட்டர்,Calculator,E-waste,,', 'CFL bulb,சி.எப்.எல் பல்பு,CFL Bulb,Hazardous E-waste,,', 'electric fan,மின்விசிறி,Minvisiri,E-waste,,', 'keyboard,கীবோர்டு,Keyboard,E-waste,,', 'mouse,மவுஸ்,Mouse,E-waste,,', 'circuit board,பலகை,Circuit board,E-waste,,', 'laptop,மடிக்கணினி,Laptop,E-waste,,', 'tablet,டேப்லெட்,Tablet,E-waste,,', 'iron box,அயர்ன் பாக்ஸ்,Iron box,E-waste,,', 'grinder,கிரைண்டர்,Grinder,E-waste,,', 'blender,மிக்ஸி,Mixie,E-waste,,', 'wire,கேபிள்,Cable,E-waste,,'],
    'sanitary': ['diaper,டயபர்,Diaper,Wrap in newspaper,Not recyclable,', 'sanitary pad,நாப்கின்,Napkin,Wrap in newspaper,Not recyclable,', 'tissue paper,டிஷ்யூ பேப்பர்,Tissue paper,Wrap and dispose,Often confused as recyclable paper,', 'cotton swabs,பட்ஸ்,Buds,Sanitary waste,,', 'bandage,பேண்டேஜ்,Bandage,Sanitary waste,,', 'used mask,பயன்படுத்திய மாஸ்க்,Mask,Sanitary waste,,', 'medical gloves,கையுறை,Gloves,Sanitary waste,,', 'used syringe wrapper,ஊசி உறை,Oosi urai,Sanitary waste,,', 'dental floss,பல் குத்தி,Floss,Sanitary waste,,', 'wound dressing,காய மருந்து,Kaaya marunthu,Sanitary waste,,', 'wet wipes,வெட் வைப்ஸ்,Wet wipes,Sanitary waste,Not compostable,', 'baby wipes,குழந்தை வைப்ஸ்,Baby wipes,Sanitary waste,,', 'pet waste,செல்லப்பிராணி கழிவு,Pet kazhivu,Sanitary waste,,', 'blood stained cloth,ரத்த துணி,Ratha thuni,Sanitary waste,,', 'ear buds,இயர் பட்ஸ்,Ear buds,Sanitary waste,,', 'razor,ரெய்சர்,Razor,Wrap carefully,,']
  };

  int idCounter = 1;
  List<Map<String, dynamic>> itemsList = [];

  for (var category in wasteData.keys) {
    for (var itemStr in wasteData[category]!) {
      var parts = itemStr.split(',');
      itemsList.add({
        "id": idCounter.toString().padLeft(3, '0'),
        "english": parts[0],
        "tamil": parts[1],
        "tamil_phonetic": parts[2],
        "category": category,
        "disposal_note": parts[3],
        "misconception": parts.length > 4 ? parts[4] : "",
        "festival_tag": parts.length > 5 ? parts[5] : "",
        "regional_variants": []
      });
      idCounter++;
    }
  }

  File('assets/waste_items.json').writeAsStringSync(jsonEncode(itemsList));
  print('Generated 80 items in assets/waste_items.json');
}
