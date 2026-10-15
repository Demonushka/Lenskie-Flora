import 'package:flutter/material.dart';

const lifeFormLabels = {
  'herb': 'Травянистое растение',
  'subshrub': 'Кустарничек, полукустарник',
  'shrub': 'Кустарник',
  'tree': 'Дерево',
  'fern': 'Папоротник',
  'fungus': 'Гриб',
  'moss': 'Мох',
};

const flowerColorLabels = {
  'white': 'Белые',
  'yellow': 'Жёлтые',
  'pink': 'Розовые',
  'red': 'Красные',
  'purple': 'Фиолетовые, сиреневые',
  'blue': 'Синие, голубые',
  'green': 'Зеленоватые',
  'brown': 'Бурые',
  'none': 'Цветков нет',
};

const flowerColorSwatches = {
  'white': Color(0xFFF7F7F2),
  'yellow': Color(0xFFF2C94C),
  'pink': Color(0xFFF2A0C0),
  'red': Color(0xFFD64545),
  'purple': Color(0xFF9B6BC4),
  'blue': Color(0xFF5B8DEF),
  'green': Color(0xFFA6C46B),
  'brown': Color(0xFF8B5E3C),
  'none': Color(0xFFBDBDBD),
};

const leafShapeLabels = {
  'linear': 'Узкие, линейные',
  'lanceolate': 'Ланцетные',
  'oval': 'Овальные, яйцевидные',
  'heart': 'Сердцевидные, округлые',
  'divided': 'Рассечённые, лопастные',
  'compound': 'Сложные, из листочков',
  'needle': 'Игольчатые, чешуйчатые',
  'reduced': 'Листьев почти нет',
};

const habitatLabels = {
  'forest': 'Лес',
  'meadow': 'Луг, поляна',
  'steppe': 'Степной склон',
  'rocks': 'Скалы, осыпи',
  'sand': 'Пески, тукуланы',
  'wetland': 'Болото, сырые места',
  'riverbank': 'Берег реки',
};

const heightClassLabels = {
  'low': 'Низкое — до 15 см',
  'mid': 'Среднее — 15–50 см',
  'high': 'Высокое — больше 50 см',
};

const confidenceLabels = {
  'high': 'данные подтверждены несколькими источниками',
  'medium': 'данные требуют уточнения',
  'low': 'присутствие вида в парке требует проверки',
};

const monthNames = [
  'январь', 'февраль', 'март', 'апрель', 'май', 'июнь',
  'июль', 'август', 'сентябрь', 'октябрь', 'ноябрь', 'декабрь',
];

String monthsRange(List<int> months) {
  if (months.isEmpty) return 'нет данных';
  final sorted = [...months]..sort();
  if (sorted.length == 1) return monthNames[sorted.first - 1];
  return '${monthNames[sorted.first - 1]} – ${monthNames[sorted.last - 1]}';
}
