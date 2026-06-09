# Refinement AI Preparation: Planning & Requirements

## Ringkasan

Dokumen ini merangkum refinement lanjutan untuk fitur AI Interview Preparation. Fondasi saat ini sudah tersedia: user dapat membuat preparation plan, schedule dibuat berdasarkan level/language, plan aktif dapat memengaruhi interview, dan rekomendasi review dapat ditambahkan kembali ke plan.

Refinement berikut berfokus pada membuat hubungan plan dan interview lebih eksplisit, granular, persisten, dan mudah diverifikasi.

## Status Saat Ini

Yang sudah terimplementasi:

- Enum `InterviewLevel`, `InterviewStage`, dan `InterviewLanguage`.
- Generate preparation plan berdasarkan target date, level, dan language.
- Progress plan dari schedule item yang ditandai selesai.
- `InterviewPreparationContext` dari active plan.
- Interview memakai active plan sebagai konteks prompt.
- Interview otomatis memakai level/language dari active plan jika tersedia.
- Session menyimpan `linkedPlanId`.
- Review menghasilkan rekomendasi terstruktur.
- Rekomendasi review dapat ditambahkan ke active plan.
- Active plan sudah eksplisit melalui `selectedPlanId`.
- UI Plan sudah mendukung daftar multi-plan dan detail selected plan.
- Plan baru otomatis menjadi selected/active plan.
- Delete active plan memindahkan selection ke fallback plan atau `null`.
- App memanggil `loadPlans()` saat main navigation dibuat.
- Schedule item punya `id` dan `suggestedStage`.
- User bisa menekan `Practice` dari schedule item untuk membuka interview berbasis topik.
- Interview dari schedule item menyimpan `linkedScheduleItemId` dan snapshot `preparationFocusTitle`.
- Stage interview default mengikuti metadata schedule item jika tersedia.
- Test unit dan widget untuk flow utama sudah tersedia.

Keterbatasan utama:

- Plan dan session runtime masih memakai repository in-memory.
- Regenerate plan berpotensi menghapus progress lama.
- Rekomendasi review masih perlu dedupe yang lebih kuat.
- Riwayat interview/review belum tampil di Profile.
- Schedule item hanya punya status boolean, belum punya status preparation yang lebih kaya.

## Tujuan Refinement

1. Membuat plan preparation terasa sebagai pusat alur latihan, bukan hanya konteks tambahan.
2. Menghubungkan schedule item tertentu ke sesi interview tertentu.
3. Menyimpan session, review, dan rekomendasi dengan relasi yang jelas ke plan.
4. Memastikan perubahan plan tidak merusak progress user.
5. Menyediakan history/review yang bisa dipakai user untuk evaluasi berulang.
6. Menyiapkan struktur data agar mudah dipersist ke Firestore atau storage lain.

## Non-Goals

- Tidak membangun ulang seluruh UI.
- Tidak mengganti state management dari `ChangeNotifier`.
- Tidak mengganti provider AI/OpenRouter.
- Tidak membuat sistem belajar lengkap seperti LMS.
- Tidak menambahkan scoring kompleks sebelum data session dan review stabil.

## Requirements

### RQ-01: Explicit Active Plan

Status: **Sudah diimplementasikan**.

User harus bisa memilih plan aktif secara eksplisit.

Acceptance criteria:

- [x] `InterviewPlanController` memiliki state `selectedPlanId`.
- [x] Getter `activePlan` mengembalikan selected plan, bukan otomatis `plans.first`.
- [x] Jika plan baru dibuat, plan tersebut menjadi active plan.
- [x] Jika active plan dihapus, active plan berpindah ke plan terdekat atau menjadi null.
- [x] Interview setup menampilkan plan aktif yang sedang digunakan.

### RQ-02: Multi-Plan Management

Status: **Sudah diimplementasikan untuk scope minimal**.

User dapat memiliki lebih dari satu preparation plan.

Acceptance criteria:

- [x] UI menampilkan daftar ringkas plan.
- [x] User dapat memilih plan untuk melihat detail timeline.
- [x] Delete dan toggle schedule item berlaku hanya pada selected plan/detail plan yang dipilih.
- [ ] Edit selected plan belum tersedia sebagai action terpisah di UI setelah perubahan multi-plan.
- [x] Test membuktikan dua plan berbeda tidak saling mengubah progress.

### RQ-03: Practice From Schedule Item

Status: **Sudah diimplementasikan**.

User dapat memulai interview dari schedule item tertentu.

Acceptance criteria:

- [x] Setiap schedule item memiliki action `Practice`.
- [x] Action tersebut membuka interview dengan `linkedPlanId` dan `linkedScheduleItemId`.
- [x] `InterviewPreparationContext` menyertakan selected schedule item.
- [x] AI opening question menyebut atau memprioritaskan selected topic.
- [x] Session menyimpan snapshot focus topic agar history tetap valid walau plan berubah.

### RQ-04: Stage Mapping

Status: **Sudah diimplementasikan**.

Schedule item harus dapat menyarankan stage interview.

Acceptance criteria:

- [x] Schedule item memiliki metadata `suggestedStage`.
- [x] Item HR mengarah ke `InterviewStage.hr`.
- [x] Item technical mengarah ke `InterviewStage.technical`.
- [x] User tetap bisa override stage sebelum memulai interview.
- [x] Jika tidak ada metadata stage, app memakai stage pilihan user saat ini.

### RQ-05: Rich Schedule Item Status

Status: **Belum diimplementasikan**.

Schedule item perlu status lebih kaya dari boolean.

Recommended statuses:

- `notStarted`
- `inProgress`
- `completed`
- `skipped`

Acceptance criteria:

- [ ] Progress utama hanya menghitung item `completed`.
- [ ] `inProgress` dapat dipakai untuk item yang sedang dilatih lewat interview.
- [ ] UI tetap sederhana, tetapi data model siap untuk status tambahan.
- [ ] Backward compatibility: data lama `isCompleted: true` dibaca sebagai `completed`.

### RQ-06: Safe Plan Regeneration

Status: **Belum diimplementasikan**.

Regenerate plan tidak boleh menghapus progress user tanpa sengaja.

Acceptance criteria:

- [ ] Saat target date, level, atau language berubah, schedule baru dibuat dengan merge strategy.
- [ ] Item yang title dan description-nya sama mempertahankan status/progress lama.
- [ ] Item yang berasal dari review tetap dipertahankan kecuali user memilih reset total.
- [ ] UI copy membedakan `Regenerate & Preserve Progress` dan `Reset Plan`.

### RQ-07: Review Recommendation Deduplication

Status: **Belum diimplementasikan**.

Rekomendasi review tidak boleh masuk berkali-kali ke plan yang sama.

Acceptance criteria:

- [ ] `appendReviewRecommendations` mengecek kombinasi `sourceReviewId` dan `sourceRecommendationId`.
- [ ] Jika rekomendasi sudah ada, item tidak ditambahkan ulang.
- [x] Tombol review menampilkan `Added to active plan` setelah rekomendasi berhasil ditambahkan.
- [ ] Tombol review belum menghitung state linked dari semua rekomendasi yang sudah ada.
- [ ] Test membuktikan double tap tidak membuat duplicate schedule item.

### RQ-08: Persistent Storage

Status: **Sebagian kecil sudah siap, persistence belum diimplementasikan**.

Plan, session, dan review perlu tersimpan permanen.

Acceptance criteria:

- [x] Repository interface tetap dipertahankan.
- [x] Implementasi in-memory tetap digunakan untuk test.
- [ ] Implementasi persistent dapat memakai Firestore atau local storage.
- [ ] App tidak lagi bergantung pada `demo_user` untuk production flow.
- [ ] Data plan muncul kembali setelah app restart.

### RQ-09: Interview History & Profile

Status: **Sebagian di data layer, UI Profile belum diimplementasikan**.

Profile harus menampilkan riwayat interview dan review.

Acceptance criteria:

- [ ] Profile screen menampilkan daftar session selesai.
- [ ] Setiap item menampilkan level, stage, language, date, dan linked plan jika ada.
- [ ] User dapat membuka detail review.
- [ ] Filter minimal: level dan stage.
- [ ] Review detail menampilkan summary, feedback, improvement areas, recommendations, dan plan links.

### RQ-10: Plan-Aware Review

Status: **Sebagian sudah ada untuk active plan, belum sampai selected schedule item**.

Review harus menjelaskan hubungan jawaban user dengan preparation plan.

Acceptance criteria:

- [ ] Jika interview memakai selected schedule item, review menyertakan feedback untuk topic itu.
- [x] Improvement areas/recommendations sudah bisa dipengaruhi konteks active plan.
- [ ] Recommendations dapat membawa `linkedPlanId` dan `linkedScheduleItemId`.
- [ ] AI prompt review menyertakan plan progress dan selected focus.

### RQ-11: Free Practice vs Plan-Guided Practice

Status: **Sebagian, belum ada toggle eksplisit**.

Interview setup perlu membedakan latihan bebas dan latihan dari plan.

Acceptance criteria:

- [x] Jika tidak ada active plan, interview berjalan sebagai free practice.
- [x] Jika ada active plan, setup menampilkan notice bahwa plan aktif diterapkan.
- [ ] User dapat memilih `Use Active Plan` atau `Practice Freely`.
- [x] Dalam free practice, level/language berasal dari dropdown user.
- [x] Dalam plan-guided practice, level/language default mengikuti active plan.

### RQ-12: Verification Coverage

Status: **Sebagian sudah diimplementasikan**.

Setiap refinement utama perlu test.

Acceptance criteria:

- [x] Unit test untuk selected active plan.
- [x] Unit test untuk preparation context dengan selected schedule item.
- [ ] Unit test untuk safe regeneration.
- [ ] Unit test untuk dedupe recommendation.
- [x] Widget test untuk `Practice This Topic`.
- [ ] Widget test untuk add review recommendation tanpa duplicate.
- [ ] Widget test untuk Profile history.
- [ ] `flutter analyze` selesai tanpa error. Saat ini masih ada info lint/deprecated lama.
- [x] `flutter test` selesai tanpa error.

## Data Model Refinement

### InterviewPlan

Recommended fields:

```dart
class InterviewPlan {
  final String id;
  final String title;
  final DateTime targetDate;
  final InterviewLevel level;
  final InterviewLanguage language;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ScheduleItem> scheduleItems;
}
```

Notes:

- `title` opsional untuk MVP, tetapi berguna untuk multi-plan.
- `updatedAt` membantu sorting dan sync.

### ScheduleItem

Recommended fields:

```dart
class ScheduleItem {
  final String id;
  final int dayOffset;
  final String title;
  final String description;
  final InterviewStage? suggestedStage;
  final ScheduleItemStatus status;
  final String? sourceReviewId;
  final String? sourceRecommendationId;
}
```

Notes:

- `id` lebih aman daripada memakai index karena urutan item bisa berubah.
- `suggestedStage` menghubungkan plan item ke interview HR/Technical.
- `status` menggantikan boolean `isCompleted`, dengan backward compatibility.

### InterviewPreparationContext

Recommended additions:

```dart
class InterviewPreparationContext {
  final String planId;
  final String? selectedScheduleItemId;
  final InterviewPreparationTopic? selectedTopic;
  final List<InterviewPreparationTopic> completedTopics;
  final List<InterviewPreparationTopic> pendingTopics;
}
```

Notes:

- `selectedTopic` menjadi fokus utama AI.
- Jika tidak ada selected topic, fallback tetap memakai pending topic pertama.

### InterviewSession

Recommended additions:

```dart
class InterviewSession {
  final String id;
  final InterviewLevel level;
  final InterviewStage stage;
  final InterviewLanguage language;
  final String? linkedPlanId;
  final String? linkedScheduleItemId;
  final String? preparationFocusTitle;
  final DateTime startedAt;
  final DateTime? endedAt;
  final List<InterviewMessage> messages;
  final InterviewReview? review;
}
```

Notes:

- `preparationFocusTitle` adalah snapshot agar history tetap bisa dibaca meski plan berubah.

## UX Flow

### Flow 1: Create and Select Plan

1. User membuka tab Plan.
2. User membuat plan baru.
3. Plan baru otomatis menjadi active plan.
4. User dapat membuat plan kedua.
5. User memilih plan mana yang aktif.
6. Interview setup memakai active plan tersebut.

### Flow 2: Practice From Schedule Item

1. User membuka detail plan.
2. User memilih schedule item `Technical Focus: State Management`.
3. User menekan `Practice`.
4. App membuka tab Interview.
5. Stage default menjadi Technical.
6. Opening question AI fokus ke State Management.
7. Session menyimpan `linkedPlanId` dan `linkedScheduleItemId`.

### Flow 3: Review Back To Plan

1. User menyelesaikan interview.
2. Review muncul dengan recommendations.
3. User menekan `Add to Active Plan`.
4. App menambahkan recommendation yang belum pernah ditambahkan.
5. Review panel menampilkan `Added to active plan`.
6. Plan timeline menampilkan item baru dengan source review metadata.

### Flow 4: Profile History

1. User membuka Profile.
2. User melihat daftar session/review.
3. User memfilter berdasarkan level atau stage.
4. User membuka detail review.
5. User melihat apakah review terkait plan dan schedule item tertentu.

## Implementation Roadmap

### Phase 1: Active Plan and Multi-Plan

Status: **Selesai untuk scope minimal**.

- [x] Tambahkan `selectedPlanId` pada `InterviewPlanController`.
- [x] Ubah `activePlan` agar memakai selected plan.
- [x] Update Plan UI untuk memilih plan.
- [x] Tambahkan test multi-plan isolation.

### Phase 2: Schedule Item Metadata

Status: **Selesai untuk scope id + suggested stage**.

- [x] Tambahkan `id` dan `suggestedStage` ke `ScheduleItem`.
- [x] Pertahankan compatibility dengan `isCompleted`.
- [x] Update generator agar memberi id stabil dan suggested stage.
- [x] Update progress calculation tetap memakai `isCompleted`.
- [ ] Rich `status` belum diterapkan karena masih masuk prioritas terpisah.

### Phase 3: Practice This Topic

Status: **Sudah diimplementasikan**.

- [x] Tambahkan selected schedule item ke `InterviewPreparationContext`.
- [x] Tambahkan action `Practice` pada schedule item.
- [x] Hubungkan action ke Interview screen.
- [x] Simpan `linkedScheduleItemId` pada session.
- [x] Tambahkan widget test opening question yang fokus ke selected topic.

### Phase 4: Safe Regeneration and Dedupe

Status: **Belum dimulai**.

- [ ] Buat merge strategy untuk regenerate plan.
- [ ] Tambahkan dedupe pada `appendReviewRecommendations`.
- [ ] Tambahkan test double-add recommendation.
- [ ] Tambahkan UI copy untuk preserve progress vs reset.

### Phase 5: Persistence and History

Status: **Sebagian kecil selesai**.

- [ ] Implement persistent repository untuk plan dan session.
- [x] Load plan saat app start.
- [ ] Buat Profile screen untuk history/review.
- [ ] Tambahkan filter level dan stage.

### Phase 6: Polish and Verification

Status: **Sebagian selesai**.

- [ ] Perjelas setup mode: free practice vs plan-guided.
- [x] Tambahkan empty/loading/error state yang konsisten untuk Plan screen.
- [x] Jalankan full regression test.
- [ ] Review prompt OpenRouter agar makin plan-aware.

## Test Plan

### Unit Tests

- `InterviewPlanController` memilih active plan secara eksplisit.
- Delete active plan memilih fallback plan yang benar.
- Toggle item hanya mengubah selected plan.
- `InterviewPreparationContext.fromPlan` menerima selected schedule item.
- `InterviewPlanGenerator` menghasilkan suggested stage.
- Regenerate plan mempertahankan completed item yang match.
- `appendReviewRecommendations` tidak membuat duplicate.
- Session menyimpan `linkedPlanId` dan `linkedScheduleItemId`.

### Widget Tests

- User membuat dua plan dan memilih active plan kedua.
- User menekan `Practice` dari schedule item dan interview memakai focus topic.
- User memilih free practice walau active plan ada.
- User menambahkan review recommendation ke plan satu kali.
- User membuka Profile dan melihat review session yang selesai.

### Manual Tests

- Create, edit, regenerate, delete plan.
- Mark item as completed, regenerate, pastikan progress tetap masuk akal.
- Start interview dari HR item dan Technical item.
- End interview, add recommendations, kembali ke Plan.
- Restart app jika persistence sudah aktif.

## Risks and Mitigations

### Risk: AI Tidak Selalu Mengikuti Focus Topic

Mitigation:

- Taruh selected topic di system prompt dan user prompt.
- Simpan focus topic di session untuk audit.
- Tambahkan test payload untuk OpenRouter service.

### Risk: Data Lama Tidak Cocok Dengan Model Baru

Mitigation:

- Buat parser backward-compatible.
- Default `id` schedule item dari hash title/description jika data lama tidak punya id.
- Baca `isCompleted` lama sebagai `ScheduleItemStatus.completed`.

### Risk: Multi-Plan Membuat UI Terlalu Padat

Mitigation:

- Tampilkan list ringkas plan di atas.
- Detail hanya untuk selected plan.
- Tetap dukung satu-plan flow sebagai default.

### Risk: Duplicate Recommendation

Mitigation:

- Dedupe berdasarkan `sourceReviewId + sourceRecommendationId`.
- Disable button saat proses append.
- Setelah append selesai, hitung ulang linked state dari active plan.

## Skala Prioritas Implementasi

Prioritas disusun berdasarkan tiga pertimbangan:

- Dampak langsung ke user flow plan-to-interview.
- Risiko teknis jika ditunda.
- Dependensi antar fitur.

### P0: Wajib Dikerjakan Dulu

P0 adalah pondasi supaya refinement berikutnya tidak dibangun di atas asumsi yang rapuh.

1. **Active plan eksplisit**
   - Status: **Selesai**.
   - Alasan: Semua flow plan-guided interview bergantung pada plan mana yang sedang aktif.
   - Dampak: Menghapus ambiguity dari `plans.first`.
   - Dependensi: Dibutuhkan oleh multi-plan, practice from schedule item, dan history.

2. **Multi-plan selection minimal**
   - Status: **Selesai untuk scope minimal**.
   - Alasan: Setelah active plan eksplisit ada, user harus bisa memilih plan.
   - Dampak: Membuat app benar-benar mendukung lebih dari satu preparation target.
   - Scope minimum: list plan ringkas, selected state, detail hanya untuk selected plan.

3. **Schedule item id dan suggested stage**
   - Status: **Selesai**.
   - Alasan: Practice dari item tertentu butuh identitas item yang stabil, bukan index.
   - Dampak: Membuka jalan ke `Practice This Topic` dan relasi session ke schedule item.
   - Scope minimum: tambah `id`, `suggestedStage`, backward compatibility untuk data lama.

### P1: High Impact Setelah Fondasi Stabil

P1 adalah fitur yang membuat hubungan plan dan interview benar-benar terasa.

4. **Practice from schedule item**
   - Status: **Selesai**.
   - Alasan: Ini refinement paling terasa untuk user.
   - Dampak: User bisa mulai interview langsung dari topik preparation.
   - Dependensi: Butuh active plan eksplisit dan schedule item id.

5. **Plan-aware preparation context dengan selected topic**
   - Status: **Selesai untuk selected topic**.
   - Alasan: AI perlu tahu topic spesifik yang sedang dilatih.
   - Dampak: Opening question, follow-up, dan review lebih relevan.
   - Dependensi: Dikerjakan bersama atau tepat setelah `Practice from schedule item`.

6. **Dedupe review recommendation**
   - Status: **Belum dikerjakan**.
   - Alasan: Risiko duplicate cukup mudah muncul dan bisa merusak timeline plan.
   - Dampak: Flow `Add to Active Plan` jadi lebih aman.
   - Scope minimum: dedupe berdasarkan `sourceReviewId + sourceRecommendationId`.

### P2: Penting, Tapi Bisa Setelah Flow Utama Nyaman

P2 meningkatkan kualitas dan keandalan, tetapi tidak harus mendahului flow utama.

7. **Safe plan regeneration**
   - Status: **Belum dikerjakan**.
   - Alasan: Progress user tidak boleh hilang saat regenerate.
   - Dampak: User lebih percaya memakai plan jangka panjang.
   - Dependensi: Lebih baik setelah schedule item punya id/status.

8. **Rich schedule status**
   - Status: **Belum dikerjakan**.
   - Alasan: Boolean `isCompleted` terlalu sempit untuk latihan nyata.
   - Dampak: Bisa membedakan not started, in progress, completed, skipped.
   - Catatan: Bisa dikerjakan bersamaan dengan safe regeneration jika ingin hemat migrasi.

9. **Free practice vs plan-guided practice toggle**
   - Status: **Sebagian, toggle eksplisit belum ada**.
   - Alasan: User perlu kontrol saat ingin interview tanpa active plan.
   - Dampak: UX lebih jelas dan tidak memaksa semua interview mengikuti plan.
   - Scope minimum: toggle sederhana di setup screen.

### P3: Strategic Follow-Up

P3 tetap penting, tetapi lebih besar cakupannya atau bergantung pada keputusan storage/auth.

10. **Persistent storage**
    - Status: **Belum dikerjakan**.
    - Alasan: Data saat ini masih runtime/in-memory.
    - Dampak: Plan, session, dan review bertahan setelah restart.
    - Catatan: Sebaiknya dilakukan setelah data model plan/session stabil agar migrasi tidak bolak-balik.

11. **Profile history dan review center**
    - Status: **Belum dikerjakan**.
    - Alasan: Review yang tersimpan perlu tempat untuk dilihat ulang.
    - Dampak: User bisa melihat perkembangan dan memfilter review.
    - Dependensi: Butuh session repository yang stabil dan idealnya persistence.

12. **Review prompt polish**
    - Status: **Sebagian, rekomendasi sudah terstruktur tetapi belum final plan-aware selected topic**.
    - Alasan: Prompt bisa dibuat lebih plan-aware setelah flow data final.
    - Dampak: Review lebih presisi.
    - Catatan: Jangan terlalu awal, karena prompt akan berubah lagi saat selected topic/session metadata berubah.

## Rekomendasi Urutan Sprint

### Sprint 1: Plan Selection Foundation

Target:

- [x] Active plan eksplisit.
- [x] Multi-plan selection minimal.
- [x] Test bahwa dua plan tidak saling mengubah progress.

Kenapa dulu:

- Ini mengunci sumber kebenaran `activePlan`.
- Setelah ini, interview tidak lagi ambigu memakai plan pertama.

### Sprint 2: Topic-Level Interview

Target:

- [x] Schedule item id.
- [x] Suggested stage.
- [x] Practice from schedule item.
- [x] Preparation context dengan selected topic.

Kenapa berikutnya:

- Ini membuat preparation plan benar-benar terhubung ke interview secara granular.
- User langsung merasakan improvement produk.

### Sprint 3: Safety and Data Integrity

Target:

- [ ] Dedupe recommendation.
- [ ] Safe regeneration.
- [ ] Rich schedule status jika masih masuk scope.

Kenapa setelah topic-level flow:

- Setelah user bisa memakai flow utama, tahap ini menjaga data timeline tetap bersih.

### Sprint 4: Persistence and Review History

Target:

- [ ] Persistent repository.
- [x] Load data saat app start.
- [ ] Profile history.
- [ ] Filter level/stage.

Kenapa belakangan:

- Persistence lebih aman dikerjakan setelah model dan relasi final.
- Mengurangi risiko migrasi data berulang.

## Urutan Implementasi Paling Disarankan

1. [x] Active plan eksplisit.
2. [x] Multi-plan selection minimal.
3. [x] Schedule item id dan suggested stage.
4. [x] Practice from schedule item.
5. [x] Selected topic di `InterviewPreparationContext`.
6. [ ] Dedupe review recommendation.
7. [ ] Safe plan regeneration.
8. [ ] Rich schedule status.
9. [ ] Free practice vs plan-guided practice toggle.
10. [ ] Persistent storage.
11. [ ] Profile history dan review center.
12. [ ] Review prompt polish.

## Definition of Done

Refinement dianggap selesai jika:

- User bisa memilih active plan.
- User bisa memulai interview dari schedule item tertentu.
- Interview menyimpan relasi ke plan dan schedule item.
- Review dapat menambahkan rekomendasi ke plan tanpa duplicate.
- Regenerate plan tidak menghapus progress penting.
- Profile menampilkan riwayat review.
- Data dapat dipersist dan dimuat ulang.
- `flutter analyze` lulus.
- `flutter test` lulus.
