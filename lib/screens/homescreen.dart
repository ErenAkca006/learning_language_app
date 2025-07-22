import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_word_app/main.dart';
import 'package:flutter_word_app/models/word.dart';
import 'package:flutter_word_app/screens/TtsVoiceSelector%20.dart';
import 'package:flutter_word_app/screens/addingScreen.dart';
import 'package:flutter_word_app/services/isar_service.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  final IsarService isarService;
  const HomeScreen({Key? key, required this.isarService}) : super(key: key);

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  //late Future<List<Word>> _getAllWord;
  late Future<List<Word>> _getAllWord = widget.isarService.getAllWords().then(
    (list) => list.reversed.toList(),
  );
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchActive = false;
  String _selectedTag = 'Tümü';
  String _searchQuery = '';
  bool _isSelecting = false;
  final Set<int> _selectedWordIds = Set<int>();
  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_handleFocusChange);
    _loadWords();
  }

  void _handleFocusChange() {
    setState(() {
      _isSearchActive = _searchFocusNode.hasFocus;
    });
  }

  void _loadWords() {
    setState(() {
      // _getAllWord = widget.isarService.getAllWords();
      _getAllWord = widget.isarService.getAllWords().then(
        (list) => list.reversed.toList(),
      );
    });
  }

  void refreshData() {
    setState(() {
      //_getAllWord = widget.isarService.getAllWords();
      _getAllWord = widget.isarService.getAllWords().then(
        (list) => list.reversed.toList(),
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.removeListener(_handleFocusChange);
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  List<Word> _filterWords(List<Word> words) {
    var filtered =
        words
            .where(
              (word) =>
                  word.word.toLowerCase().contains(_searchQuery) ||
                  word.meaning.toLowerCase().contains(_searchQuery),
            )
            .toList();

    if (_selectedTag != 'Tümü') {
      filtered = filtered.where((word) => word.type == _selectedTag).toList();
    }

    return filtered;
  }

  Color _getColorForTag(String tag) {
    switch (tag) {
      case 'İyi':
        return Colors.green[400]!;
      case 'Orta':
        return Colors.orange[400]!;
      case 'Temel':
        return Colors.red[400]!;
      default:
        return Colors.grey;
    }
  }

  void _enterSelectionMode() {
    setState(() {
      _isSelecting = true;
      _selectedWordIds.clear();
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelecting = false;
      _selectedWordIds.clear();
    });
  }

  void _toggleWordSelection(int wordId) {
    setState(() {
      if (_selectedWordIds.contains(wordId)) {
        _selectedWordIds.remove(wordId);
      } else {
        _selectedWordIds.add(wordId);
      }

      if (_selectedWordIds.isEmpty) {
        _isSelecting = false;
      }
    });
  }

  Future<void> _deleteSelectedWords() async {
    if (_selectedWordIds.isEmpty) return;

    final confirmed = await _showBulkDeleteConfirmationDialog(context);
    if (!confirmed) return;

    try {
      final deletedCount = await widget.isarService.deleteWords(
        _selectedWordIds.toList(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: BoxDecoration(
              color: Color(0xFF1E2139),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Color(0xFF6C63FF).withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '$deletedCount kelime silindi',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 20, color: Colors.white),
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  },
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
              ],
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(20),
          duration: Duration(seconds: 2),
        ),
      );

      //
      refreshData();
      _exitSelectionMode();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Silme işlemi sırasında hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<bool> _showBulkDeleteConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              contentPadding: EdgeInsets.zero,
              insetPadding: EdgeInsets.symmetric(
                horizontal: 24,
              ), // Yanlardan boşluk
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  20,
                ), // Köşeleri biraz daha yuvarlak
              ),
              content: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ), // Padding artırıldı
                decoration: BoxDecoration(
                  color: Color(0xFF1E2139),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Color(
                      0xFF6C63FF,
                    ).withOpacity(0.5), // Border opacity artırıldı
                    width: 1.5, // Border kalınlığı artırıldı
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(
                        0.4,
                      ), // Gölge koyulaştırıldı
                      blurRadius: 15, // Gölge yumuşatıldı
                      spreadRadius: 0,
                      offset: Offset(0, 6), // Gölge offset artırıldı
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Başlık Satırı - Daha fazla boşluk ve vurgu
                    Container(
                      padding: EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Color(0xFF6C63FF).withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(6),
                            child: Icon(
                              Icons.warning_rounded,
                              color: Color(0xFFFFEB3B),
                              size: 30, // İkon boyutu artırıldı
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Seçilenleri Kaldır',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 18, // Font boyutu artırıldı
                              fontWeight:
                                  FontWeight.w600, // Font ağırlığı artırıldı
                              letterSpacing: 0.5, // Harf aralığı eklendi
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Mesaj İçeriği - Daha okunaklı
                    Padding(
                      padding: EdgeInsets.only(top: 16, bottom: 24, left: 8),
                      child: Text(
                        '${_selectedWordIds.length} kelime seçildi.\nSilmek istediğinize emin misiniz?',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          height: 1.6, // Satır aralığı artırıldı
                        ),
                      ),
                    ),

                    // Butonlar - Daha modern görünüm
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // İptal Butonu - Daha belirgin
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey[300],
                            side: BorderSide(color: Colors.grey[500]!),
                            padding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text(
                            'İptal',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        SizedBox(width: 16),

                        // Sil Butonu - Gradient efekti
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            gradient: LinearGradient(
                              colors: [Color(0xFF6C63FF), Color(0xFF8A63FF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFF6C63FF).withOpacity(0.3),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                            onPressed: () => Navigator.of(context).pop(true),
                            child: Text(
                              'Sil',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ) ??
        false;
  }

  void _navigateToWordDetail(
    BuildContext context,
    Word word,
    Color color,
  ) async {
    final didUpdate = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder:
            (context) => WordDetailScreen(
              word: {
                'id': word.id,
                'word': word.word,
                'meaning': word.meaning,
                'tag': word.type,
                'color': color,
              },
              onTagChanged: (newTag) async {
                word.type = newTag;
                await widget.isarService.updateWord(word);
              },
            ),
      ),
    );

    if (didUpdate == true) {
      refreshData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_searchFocusNode.hasFocus, // Focus varsa geri tuşu engelle
      onPopInvoked: (bool didPop) async {
        if (!didPop && _searchFocusNode.hasFocus) {
          FocusScope.of(context).unfocus();
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        floatingActionButton:
            _isSearchActive
                ? null
                : FloatingActionButton(
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  foregroundColor:
                      Theme.of(context).colorScheme.onPrimaryContainer,
                  elevation: 3,
                  highlightElevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      transitionAnimationController: AnimationController(
                        duration: const Duration(milliseconds: 250),
                        vsync: Scaffold.of(context),
                      ),
                      builder: (context) {
                        return Container(
                          decoration: BoxDecoration(
                            color:
                                Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHigh,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(28),
                            ),
                          ),
                          padding: EdgeInsets.only(
                            bottom:
                                MediaQuery.of(context).viewInsets.bottom + 16,
                            top: 12,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Başlık çubuğu
                              Container(
                                width: 40,
                                height: 4,
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.outlineVariant,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),

                              // Hızlı Aksiyonlar
                              _buildActionItem(
                                context,
                                icon: Icons.add_rounded,
                                label: 'Yeni Kelime Ekle',
                                onTap: () async {
                                  Navigator.pop(context);
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => AddPage(
                                            isarService: widget.isarService,
                                          ),
                                    ),
                                  );
                                  if (result == true) refreshData();
                                },
                              ),

                              const SizedBox(height: 8),

                              _buildActionItem(
                                context,
                                icon: Icons.settings_rounded,
                                label: 'Ses Ayarları',
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TtsSettingsScreen(),
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(height: 8),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  child: const Icon(Icons.menu_rounded, size: 26),
                ),

        body: RefreshIndicator(
          onRefresh: () async => refreshData(),
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 150,
                floating: true,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title:
                      _isSelecting
                          ? Text(
                            '${_selectedWordIds.length} kelime seçildi',
                            style: GoogleFonts.poppins(),
                          )
                          : Text('Word Master', style: GoogleFonts.poppins()),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  if (_isSelecting)
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: _exitSelectionMode,
                    ),
                  if (_isSelecting)
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: _deleteSelectedWords,
                    ),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverToBoxAdapter(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Kelime ara...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          FocusScope.of(context).unfocus();
                          setState(() {});
                        },
                      ),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildTagFilter('Tümü', Colors.grey),
                        const SizedBox(width: 8),
                        _buildTagFilter('İyi', Colors.green),
                        const SizedBox(width: 8),
                        _buildTagFilter('Orta', Colors.orange),
                        const SizedBox(width: 8),
                        _buildTagFilter('Temel', Colors.red),
                      ],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: FutureBuilder<List<Word>>(
                  future: _getAllWord,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SliverToBoxAdapter(
                        child: Center(child: CircularProgressIndicator()),
                      );
                    } else if (snapshot.hasError) {
                      return SliverToBoxAdapter(
                        child: Center(child: Text('Hata: ${snapshot.error}')),
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const SliverToBoxAdapter(
                        child: Center(child: Text('Kayıtlı kelime yok.')),
                      );
                    }

                    final filtered = _filterWords(snapshot.data!);

                    if (filtered.isEmpty) {
                      return const SliverToBoxAdapter(
                        child: Center(child: Text('Sonuç bulunamadı')),
                      );
                    }
                    return SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.9,
                          ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            _buildWordCard(context, filtered[index]),
                        childCount: filtered.length,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTagFilter(String tag, Color color) {
    return ChoiceChip(
      label: Text(tag),
      selected: _selectedTag == tag,
      onSelected:
          (selected) => setState(() => _selectedTag = selected ? tag : 'Tümü'),
      selectedColor: color.withOpacity(0.2),
      labelStyle: TextStyle(
        color: _selectedTag == tag ? color : Colors.grey[400],
      ),
      side: BorderSide(color: color.withOpacity(0.5)),
    );
  }

  Widget _buildWordCard(BuildContext context, Word word) {
    final color = _getColorForTag(word.type);
    final isSelected = _selectedWordIds.contains(word.id);

    return GestureDetector(
      onTap: () {
        if (_isSelecting) {
          _toggleWordSelection(word.id);
        } else {
          _navigateToWordDetail(context, word, color);
        }
      },
      onLongPress: () {
        if (!_isSelecting) {
          _enterSelectionMode();
          _toggleWordSelection(word.id);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color:
              isSelected
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                  : Theme.of(context).cardColor,
          border:
              isSelected
                  ? Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  )
                  : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    word.word,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    word.meaning,
                    style: GoogleFonts.poppins(fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: color.withOpacity(0.5)),
                    ),
                    child: Text(
                      word.type,
                      style: GoogleFonts.poppins(fontSize: 12, color: color),
                    ),
                  ),
                ],
              ),
            ),
            if (_isSelecting)
              Positioned(
                top: 8,
                right: 8,
                child: Checkbox(
                  value: isSelected,
                  onChanged: (value) => _toggleWordSelection(word.id),
                  fillColor: MaterialStateProperty.resolveWith<Color>((
                    Set<MaterialState> states,
                  ) {
                    if (states.contains(MaterialState.selected)) {
                      return Theme.of(context).colorScheme.primary;
                    }
                    return Colors.grey;
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

Widget _buildActionItem(
  BuildContext context, {
  required IconData icon,
  required String label,
  required VoidCallback onTap,
}) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
