# AInterview Milestone Roadmap

Dokumen ini menyusun milestone implementasi berdasarkan `plan.md` untuk dua area utama:
1. **AI Interview Plan**: CRUD, scheduling, timeline persiapan, dan penyimpanan Firestore.
2. **AI Interview Chatbot**: simulasi interview HR dan Technical untuk level Intern, Junior Dev, dan Senior Dev.

## Batasan Implementasi

- Jangan mengubah file yang sudah ada di `lib/constants`.
- Jangan mengubah file yang sudah ada di `lib/widgets`.
- Gunakan widget dan design constants yang tersedia sebagaimana adanya.
- File baru untuk screen, model, provider/state management, service, dan feature logic dibuat di direktori lain seperti `lib/screens`, `lib/models`, `lib/providers`, atau `lib/services`.

## Ringkasan Prioritas

| Prioritas | Milestone | Fokus | Status Awal |
| --- | --- | --- | --- |
| P0 | Milestone 1 | Fondasi data dan struktur fitur | Belum mulai |
| P0 | Milestone 2 | CRUD Interview Plan dan Firestore | Belum mulai |
| P0 | Milestone 3 | Generator schedule persiapan | Belum mulai |
| P1 | Milestone 4 | UI Interview Plan | Belum mulai |
| P1 | Milestone 5 | AI Interview Chatbot berbasis teks | Belum mulai |
| P2 | Milestone 6 | Voice input dan voice response | Belum mulai |
| P2 | Milestone 7 | Review hasil interview | Belum mulai |
| P0 | Milestone 8 | Verification dan stabilization | Belum mulai |

---

## Milestone 1: Fondasi Data dan Struktur Fitur

### Tujuan
Menyiapkan fondasi data dan struktur folder agar fitur Interview Plan dan Interview Chatbot dapat dikembangkan tanpa menyentuh direktori yang dibatasi.

### Deliverable
- Model data interview plan.
- Model data schedule item.
- Definisi level interview: Intern, Junior Dev, Senior Dev.
- Definisi bahasa interview: Indonesian, English.
- Definisi stage interview: HR, Technical.
- Struktur folder baru untuk model, service, provider/state management, dan screen.

### Dependensi
- Authenticated user tersedia agar data plan dapat dikaitkan dengan `userId`.
- Struktur project Flutter saat ini tetap dipertahankan.

### Kriteria Selesai
- Struktur data mengikuti schema Firestore dari `plan.md`.
- Model mendukung serialize dan deserialize data Firestore.
- Tidak ada perubahan pada `lib/constants` dan `lib/widgets`.

---

## Milestone 2: CRUD Interview Plan dan Firestore

### Tujuan
Membangun kemampuan menyimpan dan mengelola interview preparation plan milik user.

### Deliverable
- Firestore service untuk path `users/{userId}/plans`.
- Fungsi create plan.
- Fungsi read/list plan.
- Fungsi update target date, level, dan language.
- Fungsi delete plan.
- Fungsi mark schedule item sebagai completed.
- State management untuk list plan dan detail plan.

### Dependensi
- Milestone 1 selesai.
- Firebase Auth dan Firestore sudah tersedia di project.

### Kriteria Selesai
- User dapat membuat plan dengan target date, level, dan language.
- Plan tersimpan di subcollection milik user yang sedang login.
- Plan dapat dimuat ulang setelah aplikasi dibuka kembali.
- Edit target date, level, atau language memperbarui data plan.
- Delete plan menghapus data dari Firestore.

---

## Milestone 3: Generator Schedule Persiapan

### Tujuan
Membuat generator awal untuk timeline persiapan interview sebelum integrasi AI penuh.

### Deliverable
- Rule-based schedule generator berdasarkan sisa hari menuju target interview.
- Template schedule untuk level Intern.
- Template schedule untuk level Junior Dev.
- Template schedule untuk level Senior Dev.
- Template task HR preparation.
- Template task Technical preparation.
- Output `scheduleItems` otomatis saat plan dibuat atau diperbarui.

### Scope Topik
- Intern: core programming, data structure dasar, OOP, Flutter/Dart atau mobile platform basics.
- Junior Dev: state management, API/networking, database integration, Git, debugging.
- Senior Dev: Clean Architecture, MVVM, system design, optimization, testing, security, team collaboration.

### Dependensi
- Milestone 1 selesai.
- Milestone 2 minimal sudah memiliki create/update plan.

### Kriteria Selesai
- Setiap plan baru otomatis memiliki schedule item.
- Perubahan target date atau level memicu recalculation schedule.
- Timeline tetap masuk akal untuk durasi pendek maupun panjang.
- Bahasa schedule mengikuti pilihan Indonesian atau English.

---

## Milestone 4: UI Interview Plan

### Tujuan
Menyediakan flow UI lengkap untuk membuat, melihat, mengubah, menyelesaikan task, dan menghapus preparation plan.

### Deliverable
- Section atau tab Interview Plan di Dashboard/Home.
- Countdown menuju target interview date.
- Progress completion berdasarkan schedule item.
- Plan Form Screen dengan date picker, level dropdown, language dropdown, dan tombol generate plan.
- Plan Detail Timeline Screen.
- Aksi edit plan.
- Aksi delete plan.
- Aksi mark schedule item as completed.
- Empty state, loading state, dan error state.

### Dependensi
- Milestone 1, 2, dan 3 selesai.
- Widget dan design constants existing dapat digunakan tanpa modifikasi.

### Kriteria Selesai
- User dapat menjalankan flow create, view, edit, mark completed, dan delete dari UI.
- Timeline tampil day-by-day.
- Progress berubah saat schedule item ditandai selesai.
- UI konsisten dengan style aplikasi yang sudah ada.

---

## Milestone 5: AI Interview Chatbot Core

### Tujuan
Membangun sesi mock interview berbasis teks untuk HR dan Technical stage di setiap level.

### Deliverable
- Interview Setup/Lobby Screen.
- Pilihan level: Intern, Junior Dev, Senior Dev.
- Pilihan stage: HR, Technical.
- Interview Session Screen berbasis chat.
- AI service handler untuk OpenRouter API.
- System instruction berbeda untuk kombinasi level dan stage.
- Transcript percakapan selama sesi.
- Tombol `End Interview & Get Review`.

### OpenRouter Model Routing

Model yang digunakan untuk sesi interview:

1. `nvidia/nemotron-3-nano-omni-30b-a3b-reasoning:free`
2. `google/gemma-4-31b-it:free`
3. `google/gemma-4-26b-a4b-it:free`

Service mencoba model secara berurutan. Jika model pertama gagal karena rate limit atau error provider, service fallback ke model berikutnya.

Untuk menjalankan app dengan OpenRouter:

```bash
flutter run --dart-define=OPENROUTER_API_KEY=your_openrouter_key
```

Jika `OPENROUTER_API_KEY` tidak diberikan, app menggunakan mock AI service agar development dan test tetap berjalan.

### Matrix System Instruction

| Level | HR Stage | Technical Stage |
| --- | --- | --- |
| Intern | Background, motivasi, komunikasi, problem solving dasar | Programming fundamentals, data structure dasar, OOP, mobile basics |
| Junior Dev | Pengalaman project, ownership, debugging mindset, collaboration | State management, API, database, Git, debugging, Flutter/Dart scenario |
| Senior Dev | Leadership, mentoring, stakeholder communication, decision making | Architecture, system design, optimization, testing strategy, security |

### Dependensi
- API key OpenRouter tersedia.
- UI navigation untuk screen baru tersedia.

### Kriteria Selesai
- User dapat memulai interview berdasarkan level dan stage.
- AI menanyakan pertanyaan sesuai konteks level dan stage.
- Chat transcript tampil dan tersimpan selama sesi berlangsung.
- HR Junior menghasilkan pertanyaan behavioral yang relevan.
- Technical Senior menghasilkan pertanyaan yang lebih kompleks dan mendalam.

---

## Milestone 6: Voice Input dan Voice Response

### Tujuan
Menambahkan pengalaman mock interview yang lebih realistis melalui speech-to-text dan text-to-speech.

### Deliverable
- Integrasi speech-to-text untuk input jawaban user.
- Integrasi text-to-speech untuk membacakan response AI.
- Voice toggle atau push-to-talk button.
- Microphone status di Interview Lobby.
- State untuk listening, processing, dan speaking.
- Fallback ke text input jika voice tidak tersedia.

### Dependensi
- Milestone 5 selesai.
- Library STT dan TTS sudah dipilih dan kompatibel dengan target platform.
- Permission microphone ditangani dengan jelas.

### Kriteria Selesai
- User dapat menjawab menggunakan suara.
- Hasil STT masuk sebagai transcript chat.
- Response AI dapat dibacakan dengan TTS.
- User tetap dapat memakai text input jika voice gagal atau permission ditolak.

---

## Milestone 7: Review Hasil Interview

### Tujuan
Memberikan evaluasi terstruktur setelah interview selesai agar user tahu area yang perlu diperbaiki.

### Deliverable
- Prompt review berdasarkan transcript interview.
- Summary performa user.
- Feedback untuk komunikasi.
- Feedback untuk technical depth.
- Feedback untuk clarity.
- Feedback untuk improvement area.
- Rekomendasi latihan berikutnya.
- Opsi menghubungkan rekomendasi dengan Interview Plan.

### Dependensi
- Milestone 5 selesai.
- Transcript interview tersedia sampai sesi berakhir.

### Kriteria Selesai
- Tombol `End Interview & Get Review` menghasilkan feedback.
- Feedback mengikuti level dan stage interview.
- Review berisi ringkasan, kekuatan, kelemahan, dan langkah latihan berikutnya.
- Rekomendasi latihan dapat digunakan untuk memperbaiki schedule persiapan.

---

## Milestone 8: Verification dan Stabilization

### Tujuan
Memastikan seluruh fitur stabil, sesuai requirement, dan tidak melanggar batasan implementasi.

### Deliverable
- Manual test plan untuk Interview Plan flow.
- Manual test plan untuk AI Chatbot flow.
- Verifikasi Firestore create, read, update, delete.
- Verifikasi schedule recalculation.
- Verifikasi Gemini API atau equivalent service handler.
- Verifikasi STT dan TTS.
- Bug fixing hasil testing.
- Final regression pass untuk memastikan direktori terbatas tidak berubah.

### Manual Verification Checklist

- Create plan dengan target date, level, dan language.
- View plan dan pastikan timeline muncul.
- Edit target date dan pastikan timeline dihitung ulang.
- Edit level dan pastikan topik berubah sesuai level baru.
- Mark schedule item as completed dan pastikan progress berubah.
- Delete plan dan pastikan data hilang dari Firestore.
- Mulai HR interview untuk Junior Dev dan pastikan pertanyaan sesuai konteks behavioral.
- Mulai Technical interview untuk Senior Dev dan pastikan pertanyaan membahas architecture, optimization, testing, dan security.
- Coba input text pada interview session.
- Coba voice input dan voice response.
- Coba fallback text input saat voice tidak tersedia.

### Kriteria Selesai
- Semua flow utama berjalan dari UI.
- Data Firestore berada di user yang benar.
- AI response mengikuti level dan stage.
- Voice feature berjalan atau fallback tersedia.
- Tidak ada perubahan pada file existing di `lib/constants` dan `lib/widgets`.

---

## Urutan Implementasi yang Disarankan

1. Milestone 1: Fondasi Data dan Struktur Fitur.
2. Milestone 2: CRUD Interview Plan dan Firestore.
3. Milestone 3: Generator Schedule Persiapan.
4. Milestone 4: UI Interview Plan.
5. Milestone 5: AI Interview Chatbot Core.
6. Milestone 7: Review Hasil Interview.
7. Milestone 6: Voice Input dan Voice Response.
8. Milestone 8: Verification dan Stabilization.

Catatan: Milestone 7 dapat dikerjakan sebelum Milestone 6 karena review hanya membutuhkan transcript text. Voice bisa ditambahkan setelah alur interview text stabil.
