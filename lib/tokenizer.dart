import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class RobertaTokenizer {
  late Map<String, int> vocab;
  late List<List<String>> merges;
  late Map<String, int> bpeRanks;
  final int maxLength;

  RobertaTokenizer({this.maxLength = 128});

  Future<void> loadTokenizer(String vocabPath, String mergesPath) async {
    // Load vocab.json
    final vocabJson = await rootBundle.loadString(vocabPath);
    vocab = Map<String, int>.from(json.decode(vocabJson));

    // Load merges.txt
    final mergesRaw = await rootBundle.loadString(mergesPath);
    final lines = mergesRaw.split('\n')
        .where((line) => line.trim().isNotEmpty && !line.startsWith('#'))
        .toList();
    merges = lines.map((line) => line.split(' ')).toList();

    // Create BPE ranks
    bpeRanks = {
      for (var i = 0; i < merges.length; i++) merges[i].join(' '): i
    };
  }

  List<String> _whitespaceTokenize(String text) {
    return text.trim().split(RegExp(r'\s+'));
  }

  String _bytesToUnicode(String text) {
    final bytes = utf8.encode(text);
    return String.fromCharCodes(bytes);
  }

  List<String> _bpe(String token) {
    if (token.isEmpty) return [];
    var word = token.split('');
    var pairs = <String>[];
    for (int i = 0; i < word.length - 1; i++) {
      pairs.add('${word[i]} ${word[i + 1]}');
    }

    while (true) {
      String? bigram;
      int minRank = 1 << 30;
      for (var pair in pairs) {
        final rank = bpeRanks[pair];
        if (rank != null && rank < minRank) {
          minRank = rank;
          bigram = pair;
        }
      }

      if (bigram == null) break;
      final parts = bigram.split(' ');
      final first = parts[0], second = parts[1];

      final newWord = <String>[];
      int i = 0;
      while (i < word.length) {
        if (i < word.length - 1 && word[i] == first && word[i + 1] == second) {
          newWord.add(first + second);
          i += 2;
        } else {
          newWord.add(word[i]);
          i += 1;
        }
      }
      word = newWord;

      if (word.length == 1) break;
      pairs = [];
      for (int i = 0; i < word.length - 1; i++) {
        pairs.add('${word[i]} ${word[i + 1]}');
      }
    }
    return word;
  }

  Map<String, dynamic> tokenize(String text) {
    final tokens = <int>[];
    final attention = <int>[];

    // Special <s>
    tokens.add(vocab['<s>']!);

    final words = _whitespaceTokenize(text);
    for (final word in words) {
      final clean = _bytesToUnicode(word.toLowerCase());
      final wordTokens = _bpe(clean);
      for (var t in wordTokens) {
        if (vocab.containsKey(t)) tokens.add(vocab[t]!);
      }
    }

    // Special </s>
    tokens.add(vocab['</s>']!);

    // Truncate or pad
    final padId = vocab['<pad>'] ?? 1;
    if (tokens.length > maxLength) {
      tokens.removeRange(maxLength, tokens.length);
    }
    attention.addAll(List.filled(tokens.length, 1));

    while (tokens.length < maxLength) {
      tokens.add(padId);
      attention.add(0);
    }

    return {
      'input_ids': tokens,
      'attention_mask': attention,
    };
  }
}
