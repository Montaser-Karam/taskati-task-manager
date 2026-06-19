import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('taskBox');
  await Hive.openBox('doneBox');
  await Hive.openBox('userBox');

  runApp(TaskatiApp());
}

class TaskatiApp extends StatelessWidget {
  const TaskatiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const TaskatiHomeScreen(),
    );
  }
}

class TaskatiHomeScreen extends StatefulWidget {
  const TaskatiHomeScreen({super.key});

  @override
  State<TaskatiHomeScreen> createState() => _TaskatiHomeScreenState();
}

class _TaskatiHomeScreenState extends State<TaskatiHomeScreen> {
  final Box taskBox = Hive.box('taskBox');
  final Box doneBox = Hive.box('doneBox');
  final Box userBox = Hive.box('userBox');

  final TextEditingController _taskController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickProfileImage() async {
    var pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        userBox.put('profilePath', pickedFile.path);
      });
    }
  }

  void _addNewTask() {
    if (_taskController.text.isNotEmpty) {
      final now = DateTime.now();

      taskBox.add({
        "title": _taskController.text,
        "date": DateFormat('yyyy-MM-dd • hh:mm a').format(now),
      });
      _taskController.clear();
      Navigator.pop(context);
    }
  }

  void _markAsDone(int index, Map task) {
    doneBox.add(task);
    taskBox.deleteAt(index);
  }

  @override
  Widget build(BuildContext context) {
    String? imagePath = userBox.get('profilePath'); // قراءة مسار الصورة

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D1D1D),
        elevation: 0,
        title: const Text(
          "Taskati 🚀",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          // ويدجت عرض صورة البروفايل التفاعلية
          GestureDetector(
            onTap: _pickProfileImage,
            child: Padding(
              padding: const EdgeInsets.only(right: 15.0),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.purpleAccent,
                backgroundImage: imagePath != null
                    ? FileImage(File(imagePath))
                    : null,
                child: imagePath == null
                    ? const Icon(
                        Icons.add_a_photo,
                        size: 18,
                        color: Colors.white,
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
      body: ValueListenableBuilder(
        // نستمع لـ "درج المهام" و "درج المخلصين" معاً عند حدوث أي تعديل
        valueListenable: taskBox.listenable(),
        builder: (context, Box box, child) {
          if (box.isEmpty && doneBox.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.network(
                    'https://raw.githubusercontent.com/xvrh/lottie-flutter/master/example/assets/Mobilo/A.json',
                    height: 180,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.playlist_add_check,
                      size: 80,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "No Tasks Today! Add some.",
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(15),
            children: [
              // ================= قسم المهام النشطة =================
              if (box.isNotEmpty) ...[
                const Text(
                  "Active Tasks 📝",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.purpleAccent,
                  ),
                ),
                const SizedBox(height: 10),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: box.length,
                  itemBuilder: (context, index) {
                    final task = box.getAt(index);
                    return Card(
                      color: const Color(0xFF1D1D1D),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: IconButton(
                          icon: const Icon(
                            Icons.circle_outlined,
                            color: Colors.purpleAccent,
                          ),
                          onPressed: () => _markAsDone(
                            index,
                            task,
                          ), // نقل للمخلصين عند الضغط
                        ),
                        title: Text(
                          task["title"],
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                        subtitle: Text(
                          task["date"],
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                          ),
                          onPressed: () => box.deleteAt(index),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 25),
              ],

              // ================= قسم المهام المنتهية =================
              ValueListenableBuilder(
                valueListenable: doneBox.listenable(),
                builder: (context, Box dBox, child) {
                  if (dBox.isEmpty) return const SizedBox();
                  return kDoneSection(dBox);
                },
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.purpleAccent,
        onPressed: _showAddTaskSheet,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  // كود تصميم قسم المهام المنتهية (Done Tasks UI)
  Widget kDoneSection(Box dBox) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Completed Tasks ✅",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: dBox.length,
          itemBuilder: (context, index) {
            final taskTitle = dBox.getAt(index).toString();
            return Card(
              color: const Color(0xFF1A1A1A),
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: Text(
                  taskTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                    decoration: TextDecoration.lineThrough,
                  ), // خط في منتصف الكلام للاحترافية
                ),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                  onPressed: () => dBox.deleteAt(index),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // الـ Bottom Sheet لإضافة مهمة جديدة
  void _showAddTaskSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          top: 20,
          left: 20,
          right: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _taskController,
              decoration: InputDecoration(
                hintText: "What do you need to do?",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purpleAccent,
                ),
                onPressed: _addNewTask,
                child: const Text(
                  "Save Task",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
