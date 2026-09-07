import 'package:televerse/telegram.dart';
import 'package:televerse/televerse.dart';
import 'database.dart';
import 'dart:math';
import 'package:shamsi_date/shamsi_date.dart';

String formatPersianDate(String date) {
  final dateTime = DateTime.parse(date);

  final j = Jalali.fromDateTime(dateTime);

  return "${j.day} ${j.formatter.mN} ${j.year}";
}

void main() async {
  initDatabase();
  final bot = Bot("8910553083:AAHcr1RktvJ6qsS2LjgpDGABIPp-xkCk_Qc");

  const int adminId = 6280174577;
  bool waitingForUserId = false;
  bool waitingForMessage = false;
  int? targetUserId;
  final userPrice = <int, int>{};
  final serviceUsername = <int, String>{};
  final SelectVolume = <int, String>{};
  final serviceTitle = <int, String>{};
  final adminAction = <int, String>{};
  final waitingCustomVolume = <int, bool>{};
  final waitingCustomTime = <int, bool>{};
  // =========================
  // سیستم جعبه شانس
  // =========================

  // =======================
  // Lucky Box
  // =======================

  final random = Random();

  final gifts = [
    {"title": "4 گیگ هدیه - 7 روزه", "weight": 25},
    {"title": "20 درصد تخفیف برای خرید بعدی", "weight": 30},
    {"title": "افزودن 3 گیگ هدیه روی سرویس فعلی", "weight": 30},
    {"title": "سرویس نامحدود 7 روزه تک کاربر", "weight": 7},
    {"title": "50 درصد تخفیف برای خرید بالای 60 گیگ", "weight": 8},
  ];

  String drawLuckyGift() {
    final totalWeight = gifts.fold<int>(0, (sum, gift) => sum + (gift["weight"] as int));

    int randomNumber = random.nextInt(totalWeight);

    for (final gift in gifts) {
      final weight = gift["weight"] as int;

      if (randomNumber < weight) {
        return gift["title"] as String;
      }

      randomNumber -= weight;
    }

    return gifts.first["title"] as String;
  }

  final SelectTime = <int, String>{};
  final orders = <int, Map<String, dynamic>>{};
  int? userCount;

  bool isUserBlocked(int userId) {
    final result = db.select('SELECT blocked FROM users WHERE id = ?', [userId]);

    if (result.isEmpty) {
      return false;
    }
    return result.first['blocked'] == 1;
  }

  final prices = {
    "15-30": 75,
    "25-30": 125,
    "30-30": 150,
    "50-30": 250,
    "15-60": 100,
    "25-60": 150,
    "30-60": 175,
    "50-60": 275,
  };

  final keyboardHome = Keyboard()
      .text("🛒 خرید سرویس")
      .row()
      .text("🎉🎁 سرویس تست[رایگان]")
      .text("📦 سرویس‌های من")
      .row()
      .text("💰 لیست قیمت")
      .text("📚 آموزش اتصال")
      .row()
      .text("☎️ پشتیبانی")
      .text("📢 کانال ما")
      .resized()
      .oneTime();

  final KeyboardBuy = Keyboard().text("حجمی 📦").text("نامحدود ♾️").row().text("بازگشت 🔙").resized().oneTime();

  final channelButton = InlineKeyboard().addUrl("📢 عضویت در کانال", "https://t.me/GEZIR33_VPN");

  final KeyboardBack = Keyboard().text("بازگشت به منوی اصلی 🔙").resized().oneTime();

  final KeyboardAdmin = Keyboard()
      .text("📢 ارسال پیام به همه")
      .text("📩 ارسال پیام به کاربر خاص")
      .row()
      .text("🚫 مسدود کردن کاربر")
      .text("✅ رفع مسدودی کاربر")
      .row()
      .text("👥 کاربران")
      .text("👥🚫 کاربران مسدود شده")
      .row()
      .text("🎁 ارسال جعبه شانس")
      .text("بازگشت 🔙")
      .resized()
      .oneTime();

  final KeyboardVolume = Keyboard()
      .text("15 گیگ")
      .text("25 گیگ")
      .row()
      .text("30 گیگ")
      .text("50 گیگ")
      .row()
      .text("✍️ دلخواه")
      .text("بازگشت 🔙")
      .resized()
      .oneTime();

  final KeyboardTimeService = Keyboard().text("30 روزه").text("60 روزه").row().text("بازگشت 🔙").resized().oneTime();

  final KeyboardConfirm = Keyboard().text("ثبت سفارش ✅").text("بازگشت 🔙").resized().oneTime();

  void resetOrder(int userId) {
    serviceUsername.remove(userId);
    SelectVolume.remove(userId);
    SelectTime.remove(userId);
    serviceTitle.remove(userId);
    userPrice.remove(userId);
  }

  final KeyboardNamahdood = Keyboard()
      .text("یکماهه 1 کاربر ♾️")
      .text("یکماهه 2 کاربر ♾️")
      .row()
      .text("یکماهه 3 کاربر ♾️")
      .text("بازگشت 🔙")
      .resized()
      .oneTime();

  bot.command("id", (ctx) async {
    await ctx.reply("ChatId شما:\n<code>${ctx.chat?.id}</code>", replyMarkup: keyboardHome, parseMode: ParseMode.html);
  });
  final now = DateTime.now();

  bot.command("start", (ctx) async {
    resetOrder(ctx.from!.id);
    db.execute("INSERT OR IGNORE INTO users(id,first_name,username,DateTime) VALUES (? ,? ,? ,?)", [
      ctx.from!.id,
      ctx.from!.firstName,
      ctx.from!.username,
      now.toString(),
    ]);

    await ctx.reply(
      "سلام ${ctx.from!.firstName}👋\n به ربات GEZIR33 VPN خوش آمدید🤩 \n لطفا یکی از گزینه های زیر را انتخاب کنید👇",
      replyMarkup: keyboardHome,
    );
  });
  bot.onMessage((ctx) async {
    /* final adminKeyboard = InlineKeyboard()
        .add("✅ تایید", "approve_${ctx.from!.id}")
        .add("❌ رد", "reject_${ctx.from!.id}"); */

    final text = ctx.message?.text;

    final userId = ctx.from!.id;

    if (userId != adminId && isUserBlocked(userId)) {
      await ctx.reply("🚫 دسترسی شما به ربات مسدود شده است");

      return;
    }
    if (userId == adminId && adminAction.containsKey(userId)) {
      final action = adminAction[userId];

      if (action == "broadcast") {
        final messageText = text;

        if (messageText == null || messageText.trim().isEmpty) {
          await ctx.reply("❌ فقط متن قابل قبول است\n\n‼️ لطفا یک متن ارسال کنید");
          return;
        }
        final users = db.select("SELECT id FROM users");
        int sent = 0;

        for (final user in users) {
          final targetUserId = user["id"] as int;

          try {
            await bot.api.sendMessage(ChatID(targetUserId), messageText);
            sent++;
          } catch (_) {}
        }
        adminAction.remove(ctx.from!.id);

        await ctx.reply(
          "✅ پیام به همه کاربران ارسال شد\n\n💬 تعداد ارسال موفق: <code>$sent</code>",
          replyMarkup: KeyboardAdmin,
          parseMode: ParseMode.html,
        );
        return;
      }
      if (action == "lucky_box") {
        final targetId = int.tryParse(text ?? "");

        if (targetId == null) {
          await ctx.reply("❌ چت آیدی نامعتبر است.");
          return;
        }

        // بررسی وجود کاربر
        final user = db.select("SELECT * FROM users WHERE id = ?", [targetId]);

        if (user.isEmpty) {
          await ctx.reply("❌ این کاربر در دیتابیس ربات وجود ندارد.", replyMarkup: KeyboardAdmin);

          adminAction.remove(userId);
          return;
        }

        // بررسی اینکه جعبه فعال نداشته باشد
        final exists = db.select(
          """
    SELECT *
    FROM lucky_boxes
    WHERE user_id = ?
    AND selected = 0
    """,
          [targetId],
        );

        if (exists.isNotEmpty) {
          await ctx.reply("⚠️ این کاربر هنوز یک جعبه بازنشده دارد.", replyMarkup: KeyboardAdmin);

          adminAction.remove(userId);
          return;
        }

        // انتخاب جایزه
        final gift = drawLuckyGift();

        // ذخیره در دیتابیس
        db.execute(
          """
    INSERT INTO lucky_boxes
    (
      user_id,
      gift,
      selected,
      sent_at
    )
    VALUES (?, ?, ?, ?)
    """,
          [targetId, gift, 0, DateTime.now().toIso8601String()],
        );

        final luckyKeyboard = InlineKeyboard()
            .add("🎁1", "box_1")
            .add("🎁2", "box_2")
            .row()
            .add("🎁3", "box_3")
            .add("🎁4", "box_4")
            .row()
            .add("🎁5", "box_5");

        await bot.api.sendMessage(
          ChatID(targetId),
          "🎁🎉 جعبه شانس Gezir33✨\n\n"
          "🌟 یک هدیه ویژه برای شما در نظر گرفته ایم🎁🎉\n\n"
          "📋لیست جوایز موجود در جعبه های زیر:🌟🎉\n"
          "🏆 4 گیگ هدیه - 7روزه🤩\n"
          "🏆 20 درصد تخفیف برای خرید بعدی🤩\n"
          "🏆 افزودن 3 گیگ هدیه روی سرویس فعلی🤩\n"
          "🏆 سرویس نامحدود 7 روزه تک کاربر🤩\n"
          "🏆 50 درصد تخفیف برای خرید بالای 60 گیگ🤩\n\n"
          "🎲 فقط یک بار فرصت انتخاب دارید.‼️\n"
          "❓ یکی از جعبه های زیر را انتخاب کنید و جایزه خود را دریافت نمایید🏆",
          replyMarkup: luckyKeyboard,
        );

        await ctx.reply("✅ جعبه شانس برای کاربر ارسال شد.", replyMarkup: KeyboardAdmin);

        adminAction.remove(userId);

        return;
      }
      final targetId = int.tryParse(text ?? '');

      if (targetId == null) {
        await ctx.reply("❌ چت آیدی نامعتبر است\n\nلطفا چت آیدی معتبر وارد کنید", replyMarkup: KeyboardBack);
        return;
      }

      if (action == "block") {
        final result = db.select("SELECT blocked FROM users WHERE id = ?", [targetId]);

        if (result.isEmpty) {
          await ctx.reply("❌ کاربری با این چت آیدی پیدا نشد", replyMarkup: KeyboardBack);
          adminAction.remove(userId);
          return;
        }

        if (result.first["blocked"] == 1) {
          await ctx.reply("⚠️ این کاربر از قبل مسدود شده است", replyMarkup: KeyboardBack);
          adminAction.remove(userId);
          return;
        }

        db.execute("UPDATE users SET blocked = 1 WHERE id = ?", [targetId]);

        try {
          await bot.api.sendMessage(
            ChatID(targetId),
            "🚫 حساب کاربری شما توسط مدیر ربات مسدود شد.\n⚠️ از این لحظه امکان استفاده از ربات برای شما وجود ندارد.\n\n👤 در صورت وجود مشکل به پشتیبانی اطلاع دهید:\n@VPN_GEZIR33",
          );
        } catch (_) {}

        await ctx.reply(
          "✅ کاربر با موفقیت مسدود شد\n\n🆔 چت آیدی کاربر: <code>$targetId</code>",
          replyMarkup: KeyboardAdmin,
          parseMode: ParseMode.html,
        );

        adminAction.remove(userId);
        return;
      }

      if (action == "unblock") {
        final result = db.select("SELECT blocked FROM users WHERE id = ?", [targetId]);

        if (result.isEmpty) {
          await ctx.reply("❌ کاربری با این چت آیدی پیدا نشد", replyMarkup: KeyboardBack);
          adminAction.remove(userId);
          return;
        }

        if (result.first["blocked"] == 0) {
          await ctx.reply("ℹ️ این کاربر در حال حاضر مسدود نیست", replyMarkup: KeyboardBack);
          adminAction.remove(userId);
          return;
        }

        db.execute("UPDATE users SET blocked = 0 WHERE id = ?", [targetId]);

        try {
          await bot.api.sendMessage(
            ChatID(targetId),
            "✅ مسدودی حساب شما توسط مدیر ربات برداشته شد.\n🎉 اکنون می توانید دوباره از ربات استفاده کنید.\n\n👤 پشتیبانی:\n@VPN_GEZIR33",
          );
        } catch (e) {
          ("❌ ارسال پیام رفع مسدودی به کاربر ناموفق بود: $e");
        }

        await ctx.reply(
          "✅ مسدودی کاربر با موفقیت برداشته شد\n\n🆔 چت آیدی کاربر: <code>$targetId</code>",
          parseMode: ParseMode.html,
          replyMarkup: KeyboardAdmin,
        );

        adminAction.remove(userId);
        return;
      }
    }

    if (text == "/admin") {
      if (ctx.from!.id != 6280174577) {
        await ctx.reply("⛔ شما به این بخش دسترسی ندارید");
        return;
      }
      await ctx.reply("🧑‍💻 پنل مدیریت", replyMarkup: KeyboardAdmin);
      return;
    }
    if (text == "🚫 مسدود کردن کاربر") {
      adminAction[ctx.from!.id] = "block";

      await ctx.reply("🆔 چت آیدی کاربر را ارسال کنید", replyMarkup: ReplyKeyboardRemove());
      return;
    }
    if (text == "✅ رفع مسدودی کاربر") {
      adminAction[ctx.from!.id] = "unblock";

      await ctx.reply("🆔 چت آیدی کاربر را ارسال کنید", replyMarkup: ReplyKeyboardRemove());
      return;
    }
    if (text == "📩 ارسال پیام به کاربر خاص") {
      waitingForUserId = true;

      await ctx.reply("🆔 چت آیدی کاربر را ارسال کنید");
      return;
    }
    if (text == "🎁 ارسال جعبه شانس") {
      if (userId != adminId) {
        return;
      }
      adminAction[userId] = "lucky_box";
      await ctx.reply(
        "🎁ارسال جعبه شانس🎁\n\n"
        "🆔چت آیدی کاربر را ارسال کنید",
        replyMarkup: ReplyKeyboardRemove(),
      );
      return;
    }
    if (waitingForUserId) {
      targetUserId = int.parse(text!);

      waitingForUserId = false;
      waitingForMessage = true;

      await ctx.reply("لطفا محتوای پیام را ارسال کنید\n\n‼️محتوای قابل ارسال:‼️\nعکس\nمتن\nاستیکر");
      return;
    }
    if (waitingForMessage) {
      if (ctx.message?.photo != null) {
        final photo = ctx.message!.photo!.last.fileId;
        final caption = ctx.message?.caption ?? "";

        await bot.api.sendPhoto(ChatID(targetUserId!), InputFile.fromFileId(photo), caption: caption);
      } else if (text != null) {
        await bot.api.sendMessage(ChatID(targetUserId!), text);
      } else if (ctx.message?.sticker != null) {
        final sticker = ctx.message?.sticker;
        await bot.api.sendSticker(ChatID(targetUserId!), InputFile.fromFileId(sticker!.fileId));
      }
      waitingForMessage = false;
      targetUserId = null;

      await ctx.reply("پیام ارسال شد✅");
      return;
    }
    if (text == "👥 کاربران") {
      final count = db.select("SELECT COUNT(*) AS total FROM users");

      final users = db.select("SELECT first_name, username, id, orders_count FROM users ORDER BY id DESC");

      String message = "👥 تعداد کل کاربران: ${count.first['total']} نفر\n\n";

      message += "📋 لیست کاربران:\n\n\n";

      for (int i = 0; i < users.length; i++) {
        final user = users[i];

        message +=
            "${i + 1}. <code>${user['first_name']}</code>\n"
            "🆔 <code>${user['id']}</code>\n"
            "👤 <code>@${user['username'] ?? 'ندارد'}</code>\n"
            "🛒 Orders: ${user['orders_count']}\n_________________________________\n\n";
      }

      await ctx.reply(message, parseMode: ParseMode.html, replyMarkup: KeyboardAdmin);

      return;
    }
    //فرستادن عکس به ربات برای دریافت ایدی عکس

    /* if (ctx.message?.photo != null) {
      final fileId = ctx.message!.photo!.last.fileId;
      print(fileId);
      await ctx.reply(fileId);
    } */

    if (text == "👥🚫 کاربران مسدود شده") {
      final blockedUsers = db.select("SELECT first_name, username, id FROM users WHERE blocked = 1 ORDER BY id DESC");
      if (blockedUsers.isEmpty) {
        await ctx.reply("🚫 هیچ کاربر مسدودی وجود ندارد", replyMarkup: KeyboardAdmin);
        return;
      }
      String message = "🚫 لیست کاربران مسدود شده\n\n";

      for (int i = 0; i < blockedUsers.length; i++) {
        final user = blockedUsers[i];

        message +=
            "${i + 1}. ${user["first_name"]}\n"
            "🆔 <code>${user["id"]}</code>\n"
            "👤 @${user["username"] ?? "ندارد"}\n_________________________________\n\n";
      }
      await ctx.reply(message, parseMode: ParseMode.html, replyMarkup: KeyboardAdmin);
    }

    if (text == "📢 ارسال پیام به همه") {
      adminAction[ctx.from!.id] = "broadcast";

      await ctx.reply("📢 لطفا متن پیام را ارسال کنید", replyMarkup: ReplyKeyboardRemove());
      return;
    }

    if (text == "🛒 خرید سرویس") {
      await ctx.reply("لطفاً نوع سرویس را انتخاب کنید.", replyMarkup: KeyboardBuy);
    }
    if (text == "🎉🎁 سرویس تست[رایگان]") {
      await ctx.reply(
        "💫 برای دریافت سرویس تست رایگان به پشتیبانی پیام دهید\n☎️ پشتیبانی:\n👤 @VPN_GEZIR33",
        replyMarkup: keyboardHome,
      );
    }
    if (text == "حجمی 📦") {
      await ctx.reply("لطفا حجم مورد نظر خود را انتخاب کنید", replyMarkup: KeyboardVolume);
    }
    if (text == "15 گیگ" || text == "25 گیگ" || text == "30 گیگ" || text == "50 گیگ") {
      SelectVolume[ctx.from!.id] = text!.split(" ").first;

      await ctx.reply("لطفا مدت زمان سرویس خود را انتخاب نمایید", replyMarkup: KeyboardTimeService);
    }
    if (text == "✍️ دلخواه") {
      waitingCustomVolume[userId] = true;

      await ctx.reply(
        "📦 حجم سرویس خود را وارد کنید\n\n"
        "مثال: 18",
        replyMarkup: ReplyKeyboardRemove(),
      );
      return;
    }

    if (text == "نامحدود ♾️") {
      await ctx.reply("لطفا یکی از سرویس های نامحدود زیر را انتخاب کنید", replyMarkup: KeyboardNamahdood);
    }
    if (text == "📚 آموزش اتصال") {
      await ctx.reply(
        "آموزش اتصال به سرویس در برنامه V2rayNg(اندروید):📚\nhttps://t.me/GEZIR33_VPN/41\n\n\nآموزش اتصال به سرویس در برنامه V2Box(آیفون):📚\nhttps://t.me/GEZIR33_VPN/42",
        replyMarkup: KeyboardBack,
      );
    }

    if (text == "یکماهه 1 کاربر ♾️") {
      SelectVolume[ctx.from!.id] = "نامحدود ♾️";
      SelectTime[ctx.from!.id] = "30";
      userPrice[ctx.from!.id] = 139;
      userCount = 1;
      // serviceTitle[ctx.from!.id] = "نامحدود(120 گیگ) | 30 روزه | 1 کاربر";
      await ctx.reply(
        "👤 لطفا یک نام کاربری دلخواه برای سرویس خود ارسال کنید\n\n❗⚠️ توجه: نام کاربری باید به زبان انگلیسی باشد\n\n✍️ مثال:\n<code>GEZIR33</code>",
        replyMarkup: ReplyKeyboardRemove(),
        parseMode: ParseMode.html,
      );
      return;
    }

    if (text == "یکماهه 2 کاربر ♾️") {
      SelectVolume[ctx.from!.id] = "نامحدود ♾️";
      SelectTime[ctx.from!.id] = "30";
      userPrice[ctx.from!.id] = 229;
      userCount = 2;

      await ctx.reply(
        "👤 لطفا یک نام کاربری دلخواه برای سرویس خود ارسال کنید\n\n❗⚠️ توجه: نام کاربری باید به زبان انگلیسی باشد\n\n✍️ مثال:\n<code>GEZIR33</code>",
        replyMarkup: ReplyKeyboardRemove(),
        parseMode: ParseMode.html,
      );
      return;
    }
    if (text == "یکماهه 3 کاربر ♾️") {
      SelectTime[ctx.from!.id] = "30";
      SelectVolume[ctx.from!.id] = "نامحدود ♾️";
      userPrice[ctx.from!.id] = 309;
      userCount = 3;

      await ctx.reply(
        "👤 لطفا یک نام کاربری دلخواه برای سرویس خود ارسال کنید\n\n❗⚠️ توجه: نام کاربری باید به زبان انگلیسی باشد\n\n✍️ مثال:\n<code>GEZIR33</code>",
        replyMarkup: ReplyKeyboardRemove(),
        parseMode: ParseMode.html,
      );
      return;
    }

    if (text == "بازگشت 🔙") {
      resetOrder(ctx.from!.id);

      await ctx.reply("به منوی اصلی بازگشتید🏠\n یکی از دکمه های زیر را انتخاب کنید⏬", replyMarkup: keyboardHome);
    }
    if (text == "30 روزه" || text == "60 روزه" || text == "90 روزه") {
      SelectTime[ctx.from!.id] = text!.split(" ").first;

      final volume = SelectVolume[ctx.from!.id];
      final time = SelectTime[ctx.from!.id];
      final key = "$volume-$time";

      userPrice[ctx.from!.id] = prices[key]!;

      serviceTitle[ctx.from!.id] = "$volume گیگ | $time روزه";

      await ctx.reply(
        "👤 لطفا یک نام کاربری دلخواه برای سرویس خود ارسال کنید\n\n❗⚠️ توجه: نام کاربری باید به زبان انگلیسی باشد\n\n✍️ مثال:\n<code>GEZIR33</code>",
        replyMarkup: ReplyKeyboardRemove(),
        parseMode: ParseMode.html,
      );
      return;
    }
    if (SelectTime.containsKey(ctx.from!.id) && !serviceUsername.containsKey(ctx.from!.id)) {
      serviceUsername[ctx.from!.id] = text!;
      final price = userPrice[ctx.from!.id];

      if (SelectVolume[ctx.from!.id] == "نامحدود ♾️") {
        await ctx.reply(
          "نام کاربری شما با موفقیت ثبت شد✅\n\n\n🧾 پیش فاکتور سفارش شما👇\n\n📦 حجم: ${SelectVolume[ctx.from!.id]}\n📅 مدت زمان: ${SelectTime[ctx.from!.id]} روزه\n📱 حداکثر کاربر: $userCount\n👤 نام کاربری سرویس: ${serviceUsername[ctx.from!.id]}\n💰 مبلغ: $price هزارتومان\n\nلطفا در صورت صحیح بودن اطلاعات روی دکمه ثبت سفارش بزنید",
          replyMarkup: KeyboardConfirm,
        );
        return;
      } else if (SelectVolume[ctx.from!.id] != "نامحدود ♾️") {
        await ctx.reply(
          "نام کاربری شما با موفقیت ثبت شد✅\n\n\n🧾 پیش فاکتور سفارش شما👇\n\n📦 حجم: ${SelectVolume[ctx.from!.id]} گیگ\n📅 مدت زمان: ${SelectTime[ctx.from!.id]} روزه\n👤نام کاربری سرویس: ${serviceUsername[ctx.from!.id]}\n💰 مبلغ: $price هزارتومان\n\nلطفا در صورت صحیح بودن اطلاعات روی دکمه ثبت سفارش بزنید",
          replyMarkup: KeyboardConfirm,
        );
        return;
      }
    }
    if (text == "ثبت سفارش ✅") {
      await ctx.reply(
        "✨💳 مرحله آخر ثبت سفارش ✨💳\n \n💰لطفا مبلغ تعیین شده را به شماره کارت زیر واریز کنید\n\n<code>6277.6013.3889.8065</code>\n👤 به نام مریم حسن پور\n❗روی شماره کارت کلیک کنید تا کپی شود\n\n📌 پس از پرداخت لطفا 📷 عکس رسید را همینجا ارسال کنید\n\n⚠️ تا قبل از ارسال رسید سفارش شما ثبت نخواهد شد\n\n🌹 از اعتماد شما سپاسگزاریم ❤️",
        replyMarkup: ReplyKeyboardRemove(),
        parseMode: ParseMode.html,
      );
    }
    if (ctx.message?.photo != null) {
      final photo = ctx.message!.photo!.last.fileId;

      final userId = ctx.from!.id;
      final name = ctx.from!.firstName;
      final username = ctx.from!.username ?? "ندارد";

      final volume = SelectVolume[userId];
      final time = SelectTime[userId];
      final serviceName = serviceUsername[userId];
      final price = userPrice[userId];

      if (volume == null || time == null || serviceName == null || price == null) {
        await ctx.reply(
          "❌ اطلاعات سفارش شما کامل نیست.\nلطفاً دوباره سفارش خود را ثبت کنید.",
          replyMarkup: keyboardHome,
        );
        resetOrder(userId);
        return;
      }

      final days = int.parse(time);
      final expiryDate = DateTime.now().add(Duration(days: days));

      // ذخیره سفارش در حافظه
      final selectedUserCount = userCount /*  ?? 1 */;

      final serviceVolume = volume == "نامحدود ♾️" ? "نامحدود ♾️ | $selectedUserCount کاربر" : "$volume گیگ";

      orders[userId] = {
        "volume": serviceVolume,
        "time": time,
        "serviceName": serviceName,
        "price": price,
        "expiry": expiryDate.toString(),
        "userCount": selectedUserCount,
      };

      final adminKeyboard = InlineKeyboard().add("✅ تایید", "approve_$userId").add("❌ رد", "reject_$userId");

      await bot.api.sendMessage(
        ChatID(adminId),
        "🛒 سفارش جدید🎉\n\n👤 نام: $name\n🆔 آیدی عددی: <code>$userId</code>\n🔗 یوزرنیم تلگرام: $username\n\n📦 حجم: $volume گیگ\n📅 مدت زمان: $time روزه\n📱 حداکثر کاربر: $userCount\n👤 نام کاربری سرویس: <code>$serviceName</code>\n\n💰 مبلغ: $price هزارتومان",
        replyMarkup: adminKeyboard,
        parseMode: ParseMode.html,
      );

      await bot.api.sendPhoto(ChatID(adminId), InputFile.fromFileId(photo));

      await ctx.reply(
        "🎉 رسید پرداخت شما با موفقیت دریافت شد ✅\n\n"
        "📩 سفارش شما ثبت شد و برای بررسی به پشتیبانی ارسال گردید.\n\n"
        "⏳ لطفاً کمی صبور باشید. پس از تایید پرداخت، سرویس شما در همین ربات ارسال خواهد شد.\n\n"
        "🌹از همراهی و اعتماد شما سپاسگزاریم🌹",
        replyMarkup: KeyboardBack,
      );
      resetOrder(userId);
    }

    if (text == "☎️ پشتیبانی") {
      await ctx.reply(
        "☎️ پشتیبانی GEZIR33 VPN\n\nدر صورت داشتن هرگونه سؤال، مشکل یا درخواست، از طریق آیدی زیر با ما در ارتباط باشید.\n\n👤 @VPN_GEZIR33\n\n🙏پشتیبانی در کمتر از 10 دقیقه پاسخ می دهد",
      );
    }
    if (text == "💰 لیست قیمت") {
      final photoPrice = "AgACAgQAAxkBAAIacGqPWQwaG9VXcErkUCeIk2NjlPoeAAK5EWsburd4UKnejRV8sG4xAQADAgADeQADPQQ";
      await bot.api.sendPhoto(
        ChatID(userId),
        InputFile.fromFileId(photoPrice),
        caption:
            "💰لیست قیمت سرویس های GEZIR33 VPN\n\n💫سرویس مناسب خودتون رو انتخاب کنید و با چند کلیک سفارشتون رو ثبت کنید✅🔥\n\n🎁برای دریافت تست رایگان به پشتیبانی پیام بدین:\n👤 @VPN_GEZIR33",
        replyMarkup: KeyboardBack,
      );
    }

    if (text == "📢 کانال ما") {
      await ctx.reply(
        "📢 کانال رسمی GEZIR33 VPN\n\n🎁 تخفیف های ویژه\n📢 اطلاعیه ها\n🎁 هدایا و...\n\nاز طریق دکمه زیر عضو کانال ما شوید 👇",
        replyMarkup: channelButton,
      );
    }
    if (text == "بازگشت به منوی اصلی 🔙") {
      resetOrder(ctx.from!.id);

      await ctx.reply("به منوی اصلی بازگشتید🏠\n یکی از دکمه های زیر را انتخاب کنید⏬", replyMarkup: keyboardHome);
    }
    if (text == "📦 سرویس‌های من") {
      final userId = ctx.from!.id;
      final services = db.select("SELECT * FROM services WHERE user_id = ?", [userId]);
      if (services.isEmpty) {
        await ctx.reply("اطلاعاتی از شما در سرور یافت نشد❌", replyMarkup: keyboardHome);
        return;
      }
      final user = services.first;
      final serviceUsername = user["service_username"];
      final serviceVolume = user["service_volume"];
      final serviceExpiry = user["service_expiry"];
      final serviceStatus = user["service_status"];

      if (serviceUsername == null || serviceUsername.toString().isEmpty || serviceStatus == "inactive") {
        await ctx.reply("📦 سرویس های من:\n\n❌ در حال حاضر سرویس فعالی ندارید.", replyMarkup: keyboardHome);
        return;
      }
      String message = "📦 سرویس‌های شما:\n\n";

      for (int i = 0; i < services.length; i++) {
        final service = services[i];

        String statusText;

        switch (service["service_status"]) {
          case "active":
            statusText = "فعال🟢";
            break;
          case "expired":
            statusText = "منقضی شده🟡";
            break;
          default:
            statusText = "غیرفعال🔴";
        }

        message +=
            "🔹 سرویس ${i + 1}\n\n"
            "👤 نام کاربری: ${service["service_username"]}\n"
            "📦 حجم: ${service["service_volume"]}\n"
            "📅 تاریخ انقضا: ${formatPersianDate(service["service_expiry"])}\n"
            "📌 وضعیت: $statusText";

        if (i != services.length - 1) {
          message += "\n\n━━━━━━━━━━━━━━━━\n\n";
        }
      }

      await ctx.reply(message, replyMarkup: keyboardHome);
    }
    if (waitingCustomVolume[userId] == true) {
      final volume = int.tryParse(text ?? "");

      if (volume == null || volume <= 0) {
        await ctx.reply("❌ لطفا فقط یک عدد صحیح وارد کنید‼️\n\nمثال: 18");
        return;
      }
      SelectVolume[userId] = volume.toString();

      waitingCustomVolume.remove(userId);
      waitingCustomTime[userId] = true;

      await ctx.reply("📅 مدت زمان سرویس خود را وارد کنید\nحداقل: 1 روز\nحداکثر: 150 روز");
      return;
    }
    if (waitingCustomTime[userId] == true) {
      final days = int.tryParse(text ?? "");

      if (days == null || days < 1 || days > 150) {
        await ctx.reply("❌ مدت زمان باید بین 1 تا 150 روز باشد‼️");
        return;
      }
      SelectTime[userId] = days.toString();
      waitingCustomTime.remove(userId);

      int volume = int.parse(SelectVolume[userId]!);
      int price;

      if (days >= 1 && days <= 30) {
        price = volume * 5;
      } else if (days >= 31 && days <= 60) {
        price = (volume * 5) + 25;
      } else if (days >= 61 && days <= 90) {
        price = (volume * 5) + 45;
      } else {
        price = (volume * 5) + 70;
      }
      userPrice[userId] = price;

      await ctx.reply(
        "👤 لطفا یک نام کاربری دلخواه برای سرویس خود ارسال کنید\n\n❗⚠️ توجه: نام کاربری باید به زبان انگلیسی باشد\n\n✍️ مثال:\n<code>GEZIR33</code>",
        replyMarkup: ReplyKeyboardRemove(),
        parseMode: ParseMode.html,
      );
    }
    return;
  });

  bot.onCallbackQuery((ctx) async {
    final data = ctx.callbackQuery?.data;

    if (data == null) {
      await ctx.answerCallbackQuery();
      return;
    }

    // =========================
    // Lucky Box
    // =========================

    if (data.startsWith("box_")) {
      final userId = ctx.from!.id;

      final result = db.select(
        """
    SELECT *
    FROM lucky_boxes
    WHERE user_id = ?
    AND selected = 0
    """,
        [userId],
      );

      if (result.isEmpty) {
        await ctx.answerCallbackQuery(text: "❌ جعبه فعالی برای شما وجود ندارد.", showAlert: true);
        return;
      }

      final lucky = result.first;

      final gift = lucky["gift"].toString();

      final boxNumber = int.parse(data.replaceFirst("box_", ""));

      db.execute(
        """
    UPDATE lucky_boxes
    SET
      selected = 1,
      box_number = ?,
      selected_at = ?
    WHERE id = ?
    """,
        [boxNumber, DateTime.now().toIso8601String(), lucky["id"]],
      );

      await ctx.answerCallbackQuery(text: "🎉 جعبه شماره $boxNumber باز شد!");

      try {
        await ctx.editMessageReplyMarkup(replyMarkup: InlineKeyboard());
      } catch (_) {}

      await bot.api.sendMessage(
        ChatID(userId),
        "تبرییییییک!🎉✨🥳\n\n\n"
        "✨ شما جعبه شماره $boxNumber را انتخاب کردید\n"
        "🏆جایزه شما: {🥳$gift🥳}\n\n"
        "🌟مبارکتون باشه!❤️\n"
        "🌹از همراهی و اعتماد شما سپاسگزاریم🌹\n"
        "جایزه شما تا دقایقی دیگر در خاص ارسال می شود🎁🥳\n\n"
        "‼️ در صورت عدم دریافت جایزه به پشتیبانی اطلاع دهید:\n👤 @VPN_GEZIR33\n\n"
        "👥 ما را به دوستانتان معرفی کنید🌹",
      );

      await bot.api.sendMessage(
        ChatID(adminId),
        "🎁 نتیجه جعبه شانس\n\n"
        "🆔کاربر: <code>$userId</code>\n"
        "🎲 جعبه انتخاب شده: $boxNumber\n\n"
        "🏆 جایزه: $gift",
        parseMode: ParseMode.html,
      );
      return;
    }

    // =========================
    // تایید سفارش
    // =========================
    if (data.startsWith("approve_")) {
      final userId = int.tryParse(data.replaceFirst("approve_", ""));

      if (userId == null) {
        await ctx.answerCallbackQuery(text: "❌ اطلاعات سفارش نامعتبر است");
        return;
      }

      final order = orders[userId];

      if (order == null) {
        await ctx.answerCallbackQuery(text: "❌ اطلاعات سفارش پیدا نشد");
        return;
      }

      final serviceName = order["serviceName"];
      final volume = order["volume"];
      final expiry = order["expiry"];

      try {
        // ثبت سرویس در جدول services
        db.execute(
          """
        INSERT INTO services
        (
          user_id,
          service_username,
          service_volume,
          service_expiry,
          service_status
        )
        VALUES (?, ?, ?, ?, ?)
        """,
          [userId, serviceName, order["volume"], expiry, "active"],
        );

        // افزایش تعداد سفارش‌های کاربر
        db.execute(
          """
        UPDATE users
        SET orders_count = COALESCE(orders_count, 0) + 1
        WHERE id = ?
        """,
          [userId],
        );

        // حذف سفارش از حافظه
        orders.remove(userId);

        // ارسال پیام به کاربر
        await bot.api.sendMessage(
          ChatID(userId),
          "✅ پرداخت شما با موفقیت تایید شد 🎉\n\n"
          "🎉 سرویس شما تا چند دقیقه دیگر ارسال خواهد شد⏳\n\n"
          "👤  نام کاربری سرویس: $serviceName\n"
          "📦 حجم سرویس: $volume\n"
          "📅 تاریخ انقضا: ${formatPersianDate(expiry)}\n\n\n"
          "🌹از اعتماد شما سپاسگزاریم🌹",
        );

        // تغییر پیام ادمین
        await ctx.editMessageText(
          "سفارش با موفقیت تایید شد ✅\n\n"
          "🆔 آیدی کاربر: <code>$userId</code>\n"
          "👤 نام کاربری: <code>$serviceName</code>",
          parseMode: ParseMode.html,
        );

        await ctx.answerCallbackQuery(text: "سفارش تایید شد ✅");
      } catch (e) {
        print("Approve Error: $e");

        await ctx.answerCallbackQuery(text: "خطا در تایید سفارش❌");
      }

      return;
    }

    // =========================
    // رد سفارش
    // =========================
    if (data.startsWith("reject_")) {
      final userId = int.tryParse(data.replaceFirst("reject_", ""));

      if (userId == null) {
        await ctx.answerCallbackQuery(text: "اطلاعات سفارش نامعتبر است❌");
        return;
      }

      final order = orders[userId];

      if (order == null) {
        await ctx.answerCallbackQuery(text: "اطلاعات سفارش پیدا نشد❌");
        return;
      }

      final serviceName = order["serviceName"];

      try {
        // حذف سفارش از حافظه
        orders.remove(userId);

        // اطلاع به کاربر
        await bot.api.sendMessage(
          ChatID(userId),
          "❌ پرداخت شما تایید نشد.\n\n⚠️ در صورت وجود مشکل به پشتیبانی اطلاع دهید\n👤 @VPN_GEZIR33",
        );

        // تغییر پیام ادمین
        await ctx.editMessageText(
          "سفارش رد شد❌\n\n"
          "🆔 آیدی کاربر: <code>$userId</code>\n"
          "👤 سرویس: <code>$serviceName</code>",
          parseMode: ParseMode.html,
        );

        await ctx.answerCallbackQuery(text: "سفارش رد شد❌");
      } catch (e) {
        print("Reject Error: $e");

        await ctx.answerCallbackQuery(text: "خطا در رد سفارش❌");
      }

      return;
    }
  });
  /* await bot.api.deleteWebhook(dropPendingUpdates: true); */
  await bot.start();
}
