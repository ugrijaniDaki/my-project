using Microsoft.EntityFrameworkCore;
using Npgsql.EntityFrameworkCore.PostgreSQL;
using System.Security.Cryptography;

var builder = WebApplication.CreateBuilder(args);

// Add services
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

// Add PostgreSQL Database
var databaseUrl = Environment.GetEnvironmentVariable("DATABASE_URL");

string connectionString;
if (!string.IsNullOrEmpty(databaseUrl) && databaseUrl.StartsWith("postgresql://"))
{
    // Parse Neon style DATABASE_URL: postgresql://user:password@host/database?sslmode=require
    var urlWithoutQuery = databaseUrl.Split('?')[0];
    var uri = new Uri(urlWithoutQuery);
    var database = uri.AbsolutePath.TrimStart('/');

    // Safely parse user info
    var username = "";
    var password = "";
    if (!string.IsNullOrEmpty(uri.UserInfo))
    {
        var colonIndex = uri.UserInfo.IndexOf(':');
        if (colonIndex > 0)
        {
            username = Uri.UnescapeDataString(uri.UserInfo.Substring(0, colonIndex));
            password = Uri.UnescapeDataString(uri.UserInfo.Substring(colonIndex + 1));
        }
        else
        {
            username = Uri.UnescapeDataString(uri.UserInfo);
        }
    }

    connectionString = $"Host={uri.Host};Database={database};Username={username};Password={password};SSL Mode=Require;Trust Server Certificate=true";
    Console.WriteLine($"Connecting to: {uri.Host}/{database} as {username}");
}
else
{
    connectionString = "Host=localhost;Port=5432;Database=auradb;Username=aura;Password=aura123";
    Console.WriteLine("Using local database");
}

builder.Services.AddDbContext<AuraDbContext>(options =>
    options.UseNpgsql(connectionString));

var app = builder.Build();

app.UseCors();

// Mobile detection and redirect to Angular app
app.Use(async (context, next) =>
{
    var userAgent = context.Request.Headers["User-Agent"].ToString().ToLower();
    var path = context.Request.Path.Value?.ToLower() ?? "";

    // Check if mobile browser
    var isMobile = userAgent.Contains("mobile") ||
                   userAgent.Contains("android") ||
                   userAgent.Contains("iphone") ||
                   userAgent.Contains("ipod") ||
                   userAgent.Contains("blackberry") ||
                   userAgent.Contains("windows phone");

    // Don't redirect if already going to mobile-angular, api, admin, or static assets
    if (isMobile &&
        !path.StartsWith("/mobile-angular") &&
        !path.StartsWith("/api") &&
        !path.StartsWith("/admin") &&
        !path.Contains(".") && // Skip files with extensions
        path != "/favicon.ico")
    {
        context.Response.Redirect("/mobile-angular/");
        return;
    }

    await next();
});

app.UseDefaultFiles();
app.UseStaticFiles();

// Ensure database is created and seed data
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<AuraDbContext>();

    db.Database.EnsureCreated();

    // Run migrations for new columns (EnsureCreated doesn't update existing tables)
    try
    {
        db.Database.ExecuteSqlRaw(@"
            DO $$
            BEGIN
                IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                               WHERE table_name = 'Users' AND column_name = 'LastLoginAt') THEN
                    ALTER TABLE ""Users"" ADD COLUMN ""LastLoginAt"" TIMESTAMP NOT NULL DEFAULT NOW();
                END IF;
                IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                               WHERE table_name = 'Users' AND column_name = 'LoginCount') THEN
                    ALTER TABLE ""Users"" ADD COLUMN ""LoginCount"" INTEGER NOT NULL DEFAULT 0;
                END IF;
            END $$;
        ");

        // Create ActivityLogs table if not exists
        db.Database.ExecuteSqlRaw(@"
            CREATE TABLE IF NOT EXISTS ""ActivityLogs"" (
                ""Id"" SERIAL PRIMARY KEY,
                ""Type"" INTEGER NOT NULL DEFAULT 0,
                ""UserId"" INTEGER,
                ""UserName"" VARCHAR(255) NOT NULL DEFAULT '',
                ""UserEmail"" VARCHAR(255) NOT NULL DEFAULT '',
                ""Description"" TEXT NOT NULL DEFAULT '',
                ""RelatedId"" INTEGER,
                ""CreatedAt"" TIMESTAMP NOT NULL DEFAULT NOW()
            );
            CREATE INDEX IF NOT EXISTS ""IX_ActivityLogs_Type"" ON ""ActivityLogs"" (""Type"");
            CREATE INDEX IF NOT EXISTS ""IX_ActivityLogs_CreatedAt"" ON ""ActivityLogs"" (""CreatedAt"");
        ");

        // Fix all NULL values in existing data
        db.Database.ExecuteSqlRaw(@"
            UPDATE ""Users"" SET ""SessionToken"" = '' WHERE ""SessionToken"" IS NULL;
            UPDATE ""Users"" SET ""TokenExpiry"" = '1970-01-01' WHERE ""TokenExpiry"" IS NULL;
            UPDATE ""Users"" SET ""UpdatedAt"" = ""CreatedAt"" WHERE ""UpdatedAt"" IS NULL;
            UPDATE ""Users"" SET ""LastLoginAt"" = ""CreatedAt"" WHERE ""LastLoginAt"" IS NULL;

            UPDATE ""Reservations"" SET ""TableNumber"" = 0 WHERE ""TableNumber"" IS NULL;
            UPDATE ""Reservations"" SET ""SpecialRequests"" = '' WHERE ""SpecialRequests"" IS NULL;
            UPDATE ""Reservations"" SET ""AdminNotes"" = '' WHERE ""AdminNotes"" IS NULL;
            UPDATE ""Reservations"" SET ""UpdatedAt"" = ""CreatedAt"" WHERE ""UpdatedAt"" IS NULL;

            UPDATE ""MenuItems"" SET ""Description"" = '' WHERE ""Description"" IS NULL;
            UPDATE ""MenuItems"" SET ""ImageUrl"" = '' WHERE ""ImageUrl"" IS NULL;
            UPDATE ""MenuItems"" SET ""Allergens"" = '' WHERE ""Allergens"" IS NULL;
            UPDATE ""MenuItems"" SET ""UpdatedAt"" = ""CreatedAt"" WHERE ""UpdatedAt"" IS NULL;

            UPDATE ""DaySchedules"" SET ""OpenTime"" = '12:00' WHERE ""OpenTime"" IS NULL;
            UPDATE ""DaySchedules"" SET ""CloseTime"" = '22:00' WHERE ""CloseTime"" IS NULL;
            UPDATE ""DaySchedules"" SET ""UpdatedAt"" = NOW() WHERE ""UpdatedAt"" IS NULL;

            UPDATE ""DateOverrides"" SET ""OpenTime"" = '' WHERE ""OpenTime"" IS NULL;
            UPDATE ""DateOverrides"" SET ""CloseTime"" = '' WHERE ""CloseTime"" IS NULL;
            UPDATE ""DateOverrides"" SET ""Reason"" = '' WHERE ""Reason"" IS NULL;

            -- Make all days open by default (admin can close specific days via DateOverrides)
            UPDATE ""DaySchedules"" SET ""IsOpen"" = true;

            -- Add images to existing menu items if they don't have any
            UPDATE ""MenuItems"" SET ""ImageUrl"" = 'https://images.unsplash.com/photo-1534604973900-c43ab4c2e0ab?w=400' WHERE ""Name"" = 'Carpaccio od tune' AND (""ImageUrl"" IS NULL OR ""ImageUrl"" = '');
            UPDATE ""MenuItems"" SET ""ImageUrl"" = 'https://images.unsplash.com/photo-1572695157366-5e585ab2b69f?w=400' WHERE ""Name"" = 'Bruschetta' AND (""ImageUrl"" IS NULL OR ""ImageUrl"" = '');
            UPDATE ""MenuItems"" SET ""ImageUrl"" = 'https://images.unsplash.com/photo-1626200419199-391ae4be7a41?w=400' WHERE ""Name"" = 'Pršut i sir' AND (""ImageUrl"" IS NULL OR ""ImageUrl"" = '');
            UPDATE ""MenuItems"" SET ""ImageUrl"" = 'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?w=400' WHERE ""Name"" = 'Tartar od lososa' AND (""ImageUrl"" IS NULL OR ""ImageUrl"" = '');
            UPDATE ""MenuItems"" SET ""ImageUrl"" = 'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=400' WHERE ""Name"" = 'Juha od rajčice' AND (""ImageUrl"" IS NULL OR ""ImageUrl"" = '');
            UPDATE ""MenuItems"" SET ""ImageUrl"" = 'https://images.unsplash.com/photo-1594756202469-9ff9799b2e4e?w=400' WHERE ""Name"" = 'Riblja juha' AND (""ImageUrl"" IS NULL OR ""ImageUrl"" = '');
            UPDATE ""MenuItems"" SET ""ImageUrl"" = 'https://images.unsplash.com/photo-1603105037880-880cd4edfb0d?w=400' WHERE ""Name"" = 'Goveđa juha' AND (""ImageUrl"" IS NULL OR ""ImageUrl"" = '');
            UPDATE ""MenuItems"" SET ""ImageUrl"" = 'https://images.unsplash.com/photo-1550304943-4f24f54ddde9?w=400' WHERE ""Name"" = 'Cezar salata' AND (""ImageUrl"" IS NULL OR ""ImageUrl"" = '');
            UPDATE ""MenuItems"" SET ""ImageUrl"" = 'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?w=400' WHERE ""Name"" = 'Grčka salata' AND (""ImageUrl"" IS NULL OR ""ImageUrl"" = '');
            UPDATE ""MenuItems"" SET ""ImageUrl"" = 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400' WHERE ""Name"" = 'Salata s kozjim sirom' AND (""ImageUrl"" IS NULL OR ""ImageUrl"" = '');
            UPDATE ""MenuItems"" SET ""ImageUrl"" = 'https://images.unsplash.com/photo-1612874742237-6526221588e3?w=400' WHERE ""Name"" = 'Spaghetti Carbonara' AND (""ImageUrl"" IS NULL OR ""ImageUrl"" = '');
            UPDATE ""MenuItems"" SET ""ImageUrl"" = 'https://images.unsplash.com/photo-1563379926898-05f4575a45d8?w=400' WHERE ""Name"" = 'Penne Arrabiata' AND (""ImageUrl"" IS NULL OR ""ImageUrl"" = '');
            UPDATE ""MenuItems"" SET ""ImageUrl"" = 'https://images.unsplash.com/photo-1534422298391-e4f8c172dddb?w=400' WHERE ""Name"" = 'Crni rižot' AND (""ImageUrl"" IS NULL OR ""ImageUrl"" = '');
            UPDATE ""MenuItems"" SET ""ImageUrl"" = 'https://images.unsplash.com/photo-1556761223-4c4282c73f77?w=400' WHERE ""Name"" = 'Tagliatelle s tartufima' AND (""ImageUrl"" IS NULL OR ""ImageUrl"" = '');
            UPDATE ""MenuItems"" SET ""ImageUrl"" = 'https://images.unsplash.com/photo-1510130387422-82bed34b37e9?w=400' WHERE ""Name"" = 'Brancin na žaru' AND (""ImageUrl"" IS NULL OR ""ImageUrl"" = '');
            UPDATE ""MenuItems"" SET ""ImageUrl"" = 'https://images.unsplash.com/photo-1565680018434-b513d5e5fd47?w=400' WHERE ""Name"" = 'Hobotnica ispod peke' AND (""ImageUrl"" IS NULL OR ""ImageUrl"" = '');
            UPDATE ""MenuItems"" SET ""ImageUrl"" = 'https://images.unsplash.com/photo-1625943553852-781c6dd46faa?w=400' WHERE ""Name"" = 'Škampi na buzaru' AND (""ImageUrl"" IS NULL OR ""ImageUrl"" = '');
            UPDATE ""MenuItems"" SET ""ImageUrl"" = 'https://images.unsplash.com/photo-1544025162-d76694265947?w=400' WHERE ""Name"" = 'Tuna steak' AND (""ImageUrl"" IS NULL OR ""ImageUrl"" = '');
            UPDATE ""MenuItems"" SET ""ImageUrl"" = 'https://images.unsplash.com/photo-1600891964092-4316c288032e?w=400' WHERE ""Name"" = 'Biftek na žaru' AND (""ImageUrl"" IS NULL OR ""ImageUrl"" = '');
            UPDATE ""MenuItems"" SET ""ImageUrl"" = 'https://images.unsplash.com/photo-1514516345957-556ca7c90a29?w=400' WHERE ""Name"" = 'Janjetina ispod peke' AND (""ImageUrl"" IS NULL OR ""ImageUrl"" = '');
            UPDATE ""MenuItems"" SET ""ImageUrl"" = 'https://images.unsplash.com/photo-1432139555190-58524dae6a55?w=400' WHERE ""Name"" = 'Pureći odrezak' AND (""ImageUrl"" IS NULL OR ""ImageUrl"" = '');
            UPDATE ""MenuItems"" SET ""ImageUrl"" = 'https://images.unsplash.com/photo-1529042410759-befb1204b468?w=400' WHERE ""Name"" = 'Ćevapi' AND (""ImageUrl"" IS NULL OR ""ImageUrl"" = '');
            UPDATE ""MenuItems"" SET ""ImageUrl"" = 'https://images.unsplash.com/photo-1571877227200-a0d98ea607e9?w=400' WHERE ""Name"" = 'Tiramisu' AND (""ImageUrl"" IS NULL OR ""ImageUrl"" = '');
            UPDATE ""MenuItems"" SET ""ImageUrl"" = 'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=400' WHERE ""Name"" = 'Panna cotta' AND (""ImageUrl"" IS NULL OR ""ImageUrl"" = '');
            UPDATE ""MenuItems"" SET ""ImageUrl"" = 'https://images.unsplash.com/photo-1624353365286-3f8d62daad51?w=400' WHERE ""Name"" = 'Čokoladni lava cake' AND (""ImageUrl"" IS NULL OR ""ImageUrl"" = '');
            UPDATE ""MenuItems"" SET ""ImageUrl"" = 'https://images.unsplash.com/photo-1490474418585-ba9bad8fd0ea?w=400' WHERE ""Name"" = 'Voćna salata' AND (""ImageUrl"" IS NULL OR ""ImageUrl"" = '');
            UPDATE ""MenuItems"" SET ""ImageUrl"" = 'https://images.unsplash.com/photo-1510591509098-f4fdc6d0ff04?w=400' WHERE ""Name"" = 'Espresso' AND (""ImageUrl"" IS NULL OR ""ImageUrl"" = '');
            UPDATE ""MenuItems"" SET ""ImageUrl"" = 'https://images.unsplash.com/photo-1572442388796-11668a67e53d?w=400' WHERE ""Name"" = 'Cappuccino' AND (""ImageUrl"" IS NULL OR ""ImageUrl"" = '');
            UPDATE ""MenuItems"" SET ""ImageUrl"" = 'https://images.unsplash.com/photo-1621506289937-a8e4df240d0b?w=400' WHERE ""Name"" = 'Svježe cijeđeni sok' AND (""ImageUrl"" IS NULL OR ""ImageUrl"" = '');
            UPDATE ""MenuItems"" SET ""ImageUrl"" = 'https://images.unsplash.com/photo-1560023907-5f339617ea30?w=400' WHERE ""Name"" = 'Mineralna voda' AND (""ImageUrl"" IS NULL OR ""ImageUrl"" = '');
            UPDATE ""MenuItems"" SET ""ImageUrl"" = 'https://images.unsplash.com/photo-1523371054106-bbf80586c38c?w=400' WHERE ""Name"" = 'Domaća limunada' AND (""ImageUrl"" IS NULL OR ""ImageUrl"" = '');
            UPDATE ""MenuItems"" SET ""ImageUrl"" = 'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=400' WHERE ""Name"" = 'Specijalitet dana' AND (""ImageUrl"" IS NULL OR ""ImageUrl"" = '');
        ");
        Console.WriteLine("Database schema and data cleaned up successfully");
    }
    catch (Exception ex)
    {
        Console.WriteLine($"Migration note: {ex.Message}");
    }

    // Seed Croatian public holidays (neradni dani)
    if (!db.DateOverrides.Any())
    {
        var holidays = new List<DateOverride>();

        // Add holidays for 2026 and 2027
        foreach (var year in new[] { 2026, 2027 })
        {
            // Fixed holidays
            holidays.Add(new DateOverride { Date = new DateTime(year, 1, 1, 0, 0, 0, DateTimeKind.Utc), IsClosed = true, Reason = "Nova godina" });
            holidays.Add(new DateOverride { Date = new DateTime(year, 1, 6, 0, 0, 0, DateTimeKind.Utc), IsClosed = true, Reason = "Sveta tri kralja (Bogojavljenje)" });
            holidays.Add(new DateOverride { Date = new DateTime(year, 5, 1, 0, 0, 0, DateTimeKind.Utc), IsClosed = true, Reason = "Praznik rada" });
            holidays.Add(new DateOverride { Date = new DateTime(year, 5, 30, 0, 0, 0, DateTimeKind.Utc), IsClosed = true, Reason = "Dan državnosti" });
            holidays.Add(new DateOverride { Date = new DateTime(year, 6, 22, 0, 0, 0, DateTimeKind.Utc), IsClosed = true, Reason = "Dan antifašističke borbe" });
            holidays.Add(new DateOverride { Date = new DateTime(year, 8, 5, 0, 0, 0, DateTimeKind.Utc), IsClosed = true, Reason = "Dan pobjede i domovinske zahvalnosti" });
            holidays.Add(new DateOverride { Date = new DateTime(year, 8, 15, 0, 0, 0, DateTimeKind.Utc), IsClosed = true, Reason = "Velika Gospa" });
            holidays.Add(new DateOverride { Date = new DateTime(year, 11, 1, 0, 0, 0, DateTimeKind.Utc), IsClosed = true, Reason = "Svi sveti" });
            holidays.Add(new DateOverride { Date = new DateTime(year, 11, 18, 0, 0, 0, DateTimeKind.Utc), IsClosed = true, Reason = "Dan sjećanja na žrtve Domovinskog rata" });
            holidays.Add(new DateOverride { Date = new DateTime(year, 12, 25, 0, 0, 0, DateTimeKind.Utc), IsClosed = true, Reason = "Božić" });
            holidays.Add(new DateOverride { Date = new DateTime(year, 12, 26, 0, 0, 0, DateTimeKind.Utc), IsClosed = true, Reason = "Sveti Stjepan" });
        }

        // Easter dates (variable) - calculated for 2026 and 2027
        // 2026: Easter Sunday = April 5
        holidays.Add(new DateOverride { Date = new DateTime(2026, 4, 5, 0, 0, 0, DateTimeKind.Utc), IsClosed = true, Reason = "Uskrs" });
        holidays.Add(new DateOverride { Date = new DateTime(2026, 4, 6, 0, 0, 0, DateTimeKind.Utc), IsClosed = true, Reason = "Uskrsni ponedjeljak" });
        holidays.Add(new DateOverride { Date = new DateTime(2026, 5, 14, 0, 0, 0, DateTimeKind.Utc), IsClosed = true, Reason = "Tijelovo" }); // Corpus Christi (60 days after Easter)

        // 2027: Easter Sunday = March 28
        holidays.Add(new DateOverride { Date = new DateTime(2027, 3, 28, 0, 0, 0, DateTimeKind.Utc), IsClosed = true, Reason = "Uskrs" });
        holidays.Add(new DateOverride { Date = new DateTime(2027, 3, 29, 0, 0, 0, DateTimeKind.Utc), IsClosed = true, Reason = "Uskrsni ponedjeljak" });
        holidays.Add(new DateOverride { Date = new DateTime(2027, 5, 6, 0, 0, 0, DateTimeKind.Utc), IsClosed = true, Reason = "Tijelovo" });

        foreach (var holiday in holidays)
        {
            holiday.CreatedAt = DateTime.UtcNow;
        }

        db.DateOverrides.AddRange(holidays);
        db.SaveChanges();
        Console.WriteLine($"Seeded {holidays.Count} Croatian public holidays for 2026-2027");
    }

    // Seed admin user
    if (!db.Users.Any(u => u.IsAdmin))
    {
        var admin = new User
        {
            Name = "Administrator",
            Email = "david.kopic@aura.com",
            Phone = "",
            PasswordHash = BCrypt.Net.BCrypt.HashPassword("060307daki"),
            IsAdmin = true,
            CreatedAt = DateTime.UtcNow
        };
        db.Users.Add(admin);
        db.SaveChanges();
        Console.WriteLine("Admin user created: david.kopic@aura.com");
    }

    // Seed default schedule (Mon-Sun) - termini svakih sat vremena, 1 rezervacija po terminu
    if (!db.DaySchedules.Any())
    {
        // Termini od 12:00 do 23:00 svakih sat vremena (12 termina)
        var defaultSlots = new[] { "12:00", "13:00", "14:00", "15:00", "16:00", "17:00", "18:00", "19:00", "20:00", "21:00", "22:00", "23:00" };

        for (int i = 0; i < 7; i++)
        {
            var day = new DaySchedule
            {
                DayOfWeek = (DayOfWeekEnum)i,
                IsOpen = true, // All days open by default
                OpenTime = "12:00",
                CloseTime = "22:00"
            };
            db.DaySchedules.Add(day);
            db.SaveChanges();

            // Add time slots - 1 rezervacija po terminu
            foreach (var slotTime in defaultSlots)
            {
                db.TimeSlots.Add(new TimeSlot
                {
                    DayScheduleId = day.Id,
                    Time = slotTime,
                    MaxReservations = 1,  // Samo 1 rezervacija po terminu!
                    IsEnabled = true
                });
            }
            db.SaveChanges();
        }
        Console.WriteLine("Default schedule created (Mon-Sat open, Sun closed) - 12 slots/day, 1 reservation/slot");
    }

    // Seed menu items
    if (!db.MenuItems.Any())
    {
        var menuItems = new List<MenuItem>
        {
            // Predjela (Appetizers)
            new MenuItem { Name = "Carpaccio od tune", Description = "Svježa tuna s rukolom, kaparima i parmezanom", Price = 14.90m, Category = MenuCategory.Appetizer, ImageUrl = "https://images.unsplash.com/photo-1534604973900-c43ab4c2e0ab?w=400", IsAvailable = true, IsGlutenFree = true, SortOrder = 1, CreatedAt = DateTime.UtcNow },
            new MenuItem { Name = "Bruschetta", Description = "Hrskavi kruh s cherry rajčicama, bosiljkom i balzamiko kremom", Price = 8.90m, Category = MenuCategory.Appetizer, ImageUrl = "https://images.unsplash.com/photo-1572695157366-5e585ab2b69f?w=400", IsAvailable = true, IsVegetarian = true, IsVegan = true, SortOrder = 2, CreatedAt = DateTime.UtcNow },
            new MenuItem { Name = "Pršut i sir", Description = "Dalmatinski pršut s domaćim sirom i maslinama", Price = 12.90m, Category = MenuCategory.Appetizer, ImageUrl = "https://images.unsplash.com/photo-1626200419199-391ae4be7a41?w=400", IsAvailable = true, IsGlutenFree = true, SortOrder = 3, CreatedAt = DateTime.UtcNow },
            new MenuItem { Name = "Tartar od lososa", Description = "Svježi losos s avokadom i sezamom", Price = 15.90m, Category = MenuCategory.Appetizer, ImageUrl = "https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?w=400", IsAvailable = true, IsGlutenFree = true, SortOrder = 4, CreatedAt = DateTime.UtcNow },

            // Juhe (Soups)
            new MenuItem { Name = "Juha od rajčice", Description = "Kremasta juha od pečenih rajčica s bosiljkom", Price = 6.90m, Category = MenuCategory.Soup, ImageUrl = "https://images.unsplash.com/photo-1547592166-23ac45744acd?w=400", IsAvailable = true, IsVegetarian = true, IsVegan = true, IsGlutenFree = true, SortOrder = 1, CreatedAt = DateTime.UtcNow },
            new MenuItem { Name = "Riblja juha", Description = "Tradicionalna dalmatinska riblja juha", Price = 9.90m, Category = MenuCategory.Soup, ImageUrl = "https://images.unsplash.com/photo-1594756202469-9ff9799b2e4e?w=400", IsAvailable = true, IsGlutenFree = true, SortOrder = 2, CreatedAt = DateTime.UtcNow },
            new MenuItem { Name = "Goveđa juha", Description = "Domaća goveđa juha s rezancima", Price = 7.90m, Category = MenuCategory.Soup, ImageUrl = "https://images.unsplash.com/photo-1603105037880-880cd4edfb0d?w=400", IsAvailable = true, SortOrder = 3, CreatedAt = DateTime.UtcNow },

            // Salate (Salads)
            new MenuItem { Name = "Cezar salata", Description = "Romanska salata, piletina, parmezan, krutonsi i Cezar dressing", Price = 11.90m, Category = MenuCategory.Salad, ImageUrl = "https://images.unsplash.com/photo-1550304943-4f24f54ddde9?w=400", IsAvailable = true, SortOrder = 1, CreatedAt = DateTime.UtcNow },
            new MenuItem { Name = "Grčka salata", Description = "Rajčice, krastavci, paprika, luk, masline i feta sir", Price = 9.90m, Category = MenuCategory.Salad, ImageUrl = "https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?w=400", IsAvailable = true, IsVegetarian = true, IsGlutenFree = true, SortOrder = 2, CreatedAt = DateTime.UtcNow },
            new MenuItem { Name = "Salata s kozjim sirom", Description = "Mješana salata s toplim kozjim sirom i orasima", Price = 12.90m, Category = MenuCategory.Salad, ImageUrl = "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400", IsAvailable = true, IsVegetarian = true, IsGlutenFree = true, SortOrder = 3, CreatedAt = DateTime.UtcNow },

            // Tjestenina (Pasta)
            new MenuItem { Name = "Spaghetti Carbonara", Description = "Spaghetti s guanciale, jajima i pecorino sirom", Price = 13.90m, Category = MenuCategory.Pasta, ImageUrl = "https://images.unsplash.com/photo-1612874742237-6526221588e3?w=400", IsAvailable = true, SortOrder = 1, CreatedAt = DateTime.UtcNow },
            new MenuItem { Name = "Penne Arrabiata", Description = "Penne s ljutim umakom od rajčice", Price = 11.90m, Category = MenuCategory.Pasta, ImageUrl = "https://images.unsplash.com/photo-1563379926898-05f4575a45d8?w=400", IsAvailable = true, IsVegetarian = true, IsVegan = true, SortOrder = 2, CreatedAt = DateTime.UtcNow },
            new MenuItem { Name = "Crni rižot", Description = "Rižot s tintom od sipe i plodovima mora", Price = 16.90m, Category = MenuCategory.Pasta, ImageUrl = "https://images.unsplash.com/photo-1534422298391-e4f8c172dddb?w=400", IsAvailable = true, IsGlutenFree = true, SortOrder = 3, CreatedAt = DateTime.UtcNow },
            new MenuItem { Name = "Tagliatelle s tartufima", Description = "Domaća tjestenina s crnim tartufima", Price = 22.90m, Category = MenuCategory.Pasta, ImageUrl = "https://images.unsplash.com/photo-1556761223-4c4282c73f77?w=400", IsAvailable = true, IsVegetarian = true, SortOrder = 4, CreatedAt = DateTime.UtcNow },

            // Ribe (Fish)
            new MenuItem { Name = "Brancin na žaru", Description = "Svježi brancin s povrćem na žaru i blitvom", Price = 24.90m, Category = MenuCategory.Fish, ImageUrl = "https://images.unsplash.com/photo-1510130387422-82bed34b37e9?w=400", IsAvailable = true, IsGlutenFree = true, SortOrder = 1, CreatedAt = DateTime.UtcNow },
            new MenuItem { Name = "Hobotnica ispod peke", Description = "Hobotnica s krumpirom ispod peke", Price = 26.90m, Category = MenuCategory.Fish, ImageUrl = "https://images.unsplash.com/photo-1565680018434-b513d5e5fd47?w=400", IsAvailable = true, IsGlutenFree = true, SortOrder = 2, CreatedAt = DateTime.UtcNow },
            new MenuItem { Name = "Škampi na buzaru", Description = "Škampi u umaku od bijelog vina i češnjaka", Price = 28.90m, Category = MenuCategory.Fish, ImageUrl = "https://images.unsplash.com/photo-1625943553852-781c6dd46faa?w=400", IsAvailable = true, SortOrder = 3, CreatedAt = DateTime.UtcNow },
            new MenuItem { Name = "Tuna steak", Description = "Tuna steak srednje pečena s wakame salatom", Price = 27.90m, Category = MenuCategory.Fish, ImageUrl = "https://images.unsplash.com/photo-1544025162-d76694265947?w=400", IsAvailable = true, IsGlutenFree = true, SortOrder = 4, CreatedAt = DateTime.UtcNow },

            // Meso (Meat)
            new MenuItem { Name = "Biftek na žaru", Description = "300g biftek s pečenim povrćem i umakom od vina", Price = 32.90m, Category = MenuCategory.Meat, ImageUrl = "https://images.unsplash.com/photo-1600891964092-4316c288032e?w=400", IsAvailable = true, IsGlutenFree = true, SortOrder = 1, CreatedAt = DateTime.UtcNow },
            new MenuItem { Name = "Janjetina ispod peke", Description = "Janjetina s krumpirom ispod peke", Price = 28.90m, Category = MenuCategory.Meat, ImageUrl = "https://images.unsplash.com/photo-1514516345957-556ca7c90a29?w=400", IsAvailable = true, IsGlutenFree = true, SortOrder = 2, CreatedAt = DateTime.UtcNow },
            new MenuItem { Name = "Pureći odrezak", Description = "Pureći odrezak s pireom i umakom od gljiva", Price = 18.90m, Category = MenuCategory.Meat, ImageUrl = "https://images.unsplash.com/photo-1432139555190-58524dae6a55?w=400", IsAvailable = true, IsGlutenFree = true, SortOrder = 3, CreatedAt = DateTime.UtcNow },
            new MenuItem { Name = "Ćevapi", Description = "10 ćevapa s lepinjom, lukom i kajmakom", Price = 14.90m, Category = MenuCategory.Meat, ImageUrl = "https://images.unsplash.com/photo-1529042410759-befb1204b468?w=400", IsAvailable = true, SortOrder = 4, CreatedAt = DateTime.UtcNow },

            // Deserti (Desserts)
            new MenuItem { Name = "Tiramisu", Description = "Klasični talijanski desert s espressom i mascarponeom", Price = 7.90m, Category = MenuCategory.Dessert, ImageUrl = "https://images.unsplash.com/photo-1571877227200-a0d98ea607e9?w=400", IsAvailable = true, IsVegetarian = true, SortOrder = 1, CreatedAt = DateTime.UtcNow },
            new MenuItem { Name = "Panna cotta", Description = "Talijanski kremasti desert s voćnim umakom", Price = 6.90m, Category = MenuCategory.Dessert, ImageUrl = "https://images.unsplash.com/photo-1488477181946-6428a0291777?w=400", IsAvailable = true, IsVegetarian = true, IsGlutenFree = true, SortOrder = 2, CreatedAt = DateTime.UtcNow },
            new MenuItem { Name = "Čokoladni lava cake", Description = "Topli čokoladni kolač s tekućom jezgrom", Price = 8.90m, Category = MenuCategory.Dessert, ImageUrl = "https://images.unsplash.com/photo-1624353365286-3f8d62daad51?w=400", IsAvailable = true, IsVegetarian = true, SortOrder = 3, CreatedAt = DateTime.UtcNow },
            new MenuItem { Name = "Voćna salata", Description = "Svježe sezonsko voće s mentom", Price = 5.90m, Category = MenuCategory.Dessert, ImageUrl = "https://images.unsplash.com/photo-1490474418585-ba9bad8fd0ea?w=400", IsAvailable = true, IsVegetarian = true, IsVegan = true, IsGlutenFree = true, SortOrder = 4, CreatedAt = DateTime.UtcNow },

            // Pića (Beverages)
            new MenuItem { Name = "Espresso", Description = "Talijanska kava", Price = 2.50m, Category = MenuCategory.Beverage, ImageUrl = "https://images.unsplash.com/photo-1510591509098-f4fdc6d0ff04?w=400", IsAvailable = true, IsVegan = true, IsGlutenFree = true, SortOrder = 1, CreatedAt = DateTime.UtcNow },
            new MenuItem { Name = "Cappuccino", Description = "Espresso s mlijekom i mliječnom pjenom", Price = 3.50m, Category = MenuCategory.Beverage, ImageUrl = "https://images.unsplash.com/photo-1572442388796-11668a67e53d?w=400", IsAvailable = true, IsVegetarian = true, IsGlutenFree = true, SortOrder = 2, CreatedAt = DateTime.UtcNow },
            new MenuItem { Name = "Svježe cijeđeni sok", Description = "Naranča, jabuka ili grejp", Price = 4.50m, Category = MenuCategory.Beverage, ImageUrl = "https://images.unsplash.com/photo-1621506289937-a8e4df240d0b?w=400", IsAvailable = true, IsVegan = true, IsGlutenFree = true, SortOrder = 3, CreatedAt = DateTime.UtcNow },
            new MenuItem { Name = "Mineralna voda", Description = "0.75l", Price = 3.00m, Category = MenuCategory.Beverage, ImageUrl = "https://images.unsplash.com/photo-1560023907-5f339617ea30?w=400", IsAvailable = true, IsVegan = true, IsGlutenFree = true, SortOrder = 4, CreatedAt = DateTime.UtcNow },
            new MenuItem { Name = "Domaća limunada", Description = "Svježa limunada s mentom", Price = 4.00m, Category = MenuCategory.Beverage, ImageUrl = "https://images.unsplash.com/photo-1523371054106-bbf80586c38c?w=400", IsAvailable = true, IsVegan = true, IsGlutenFree = true, SortOrder = 5, CreatedAt = DateTime.UtcNow },

            // Specijaliteti dana (Daily Specials)
            new MenuItem { Name = "Specijalitet dana", Description = "Pitajte konobara za današnji specijalitet", Price = 19.90m, Category = MenuCategory.Special, ImageUrl = "https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=400", IsAvailable = true, SortOrder = 1, CreatedAt = DateTime.UtcNow }
        };

        db.MenuItems.AddRange(menuItems);
        db.SaveChanges();
        Console.WriteLine($"Seeded {menuItems.Count} menu items");
    }
}

// ============= HELPER FUNCTIONS =============

// Formatira ime u "Ime P." format (veliko početno slovo imena + inicijal prezimena s točkom)
string FormatDisplayName(string fullName)
{
    if (string.IsNullOrWhiteSpace(fullName)) return fullName;

    var parts = fullName.Trim().Split(' ', StringSplitOptions.RemoveEmptyEntries);
    if (parts.Length == 0) return fullName;

    // Ime - veliko početno slovo, ostalo malo
    var firstName = char.ToUpper(parts[0][0]) + parts[0].Substring(1).ToLower();

    if (parts.Length == 1)
    {
        return firstName;
    }

    // Prezime - samo inicijal s točkom
    var lastNameInitial = char.ToUpper(parts[parts.Length - 1][0]) + ".";

    return $"{firstName} {lastNameInitial}";
}

// ============= AUTH ENDPOINTS =============

// Register new user
app.MapPost("/api/auth/register", async (RegisterRequest request, AuraDbContext db) =>
{
    // Check if email already exists
    if (await db.Users.AnyAsync(u => u.Email == request.Email))
    {
        return Results.BadRequest(new { error = "Email je već registriran" });
    }

    var user = new User
    {
        Name = FormatDisplayName(request.Name),
        Email = request.Email,
        Phone = request.Phone,
        PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password),
        IsAdmin = false,
        CreatedAt = DateTime.UtcNow
    };

    db.Users.Add(user);
    await db.SaveChangesAsync();

    // Generate session token
    var token = GenerateToken();
    user.SessionToken = token;
    user.TokenExpiry = DateTime.UtcNow.AddDays(7);
    user.LastLoginAt = DateTime.UtcNow;
    user.LoginCount = 1;

    // Log activity
    db.ActivityLogs.Add(new ActivityLog
    {
        Type = ActivityType.UserRegistered,
        UserId = user.Id,
        UserName = user.Name,
        UserEmail = user.Email,
        Description = $"Novi korisnik registriran: {user.Name} ({user.Email})",
        CreatedAt = DateTime.UtcNow
    });

    await db.SaveChangesAsync();

    return Results.Ok(new {
        token,
        user = new { user.Id, user.Name, user.Email, user.Phone }
    });
});

// Login user
app.MapPost("/api/auth/login", async (LoginRequest request, AuraDbContext db) =>
{
    var user = await db.Users.FirstOrDefaultAsync(u => u.Email == request.Email && !u.IsAdmin);

    if (user == null || !BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash))
    {
        return Results.BadRequest(new { error = "Pogrešan email ili lozinka" });
    }

    // Generate new session token
    var token = GenerateToken();
    user.SessionToken = token;
    user.TokenExpiry = DateTime.UtcNow.AddDays(7);
    user.LastLoginAt = DateTime.UtcNow;
    user.LoginCount++;

    // Log activity
    db.ActivityLogs.Add(new ActivityLog
    {
        Type = ActivityType.UserLogin,
        UserId = user.Id,
        UserName = user.Name,
        UserEmail = user.Email,
        Description = $"Korisnik prijavljen: {user.Name}",
        CreatedAt = DateTime.UtcNow
    });

    await db.SaveChangesAsync();

    return Results.Ok(new {
        token,
        user = new { user.Id, user.Name, user.Email, user.Phone }
    });
});

// Admin login
app.MapPost("/api/auth/admin/login", async (LoginRequest request, AuraDbContext db) =>
{
    var admin = await db.Users.FirstOrDefaultAsync(u => u.Email == request.Email && u.IsAdmin);

    if (admin == null || !BCrypt.Net.BCrypt.Verify(request.Password, admin.PasswordHash))
    {
        return Results.BadRequest(new { error = "Pogrešan email ili lozinka" });
    }

    // Generate new session token
    var token = GenerateToken();
    admin.SessionToken = token;
    admin.TokenExpiry = DateTime.UtcNow.AddDays(1); // Admin token expires faster
    admin.LastLoginAt = DateTime.UtcNow;
    admin.LoginCount++;

    // Log activity
    db.ActivityLogs.Add(new ActivityLog
    {
        Type = ActivityType.AdminLogin,
        UserId = admin.Id,
        UserName = admin.Name,
        UserEmail = admin.Email,
        Description = $"Admin prijavljen: {admin.Name}",
        CreatedAt = DateTime.UtcNow
    });

    await db.SaveChangesAsync();

    return Results.Ok(new { token, isAdmin = true });
});

// Verify token (check if user is logged in) - produži token pri svakom pozivu
app.MapGet("/api/auth/verify", async (HttpContext context, AuraDbContext db) =>
{
    var token = context.Request.Headers["Authorization"].FirstOrDefault()?.Replace("Bearer ", "");

    if (string.IsNullOrEmpty(token))
    {
        return Results.Unauthorized();
    }

    var user = await db.Users.FirstOrDefaultAsync(u => u.SessionToken == token && u.TokenExpiry > DateTime.UtcNow);

    if (user == null)
    {
        return Results.Unauthorized();
    }

    // Produži token za još 7 dana (ili 1 dan za admina) pri svakom verify pozivu
    user.TokenExpiry = DateTime.UtcNow.AddDays(user.IsAdmin ? 1 : 7);
    await db.SaveChangesAsync();

    return Results.Ok(new {
        user = new { user.Id, user.Name, user.Email, user.Phone },
        isAdmin = user.IsAdmin
    });
});

// Logout
app.MapPost("/api/auth/logout", async (HttpContext context, AuraDbContext db) =>
{
    var token = context.Request.Headers["Authorization"].FirstOrDefault()?.Replace("Bearer ", "");

    if (!string.IsNullOrEmpty(token))
    {
        var user = await db.Users.FirstOrDefaultAsync(u => u.SessionToken == token);
        if (user != null)
        {
            // Log activity
            db.ActivityLogs.Add(new ActivityLog
            {
                Type = ActivityType.UserLogout,
                UserId = user.Id,
                UserName = user.Name,
                UserEmail = user.Email,
                Description = $"Korisnik odjavljen: {user.Name}",
                CreatedAt = DateTime.UtcNow
            });

            user.SessionToken = "";
            user.TokenExpiry = DateTime.MinValue;
            await db.SaveChangesAsync();
        }
    }

    return Results.Ok();
});

// ============= USER ENDPOINTS (Admin only) =============

app.MapGet("/api/users", async (HttpContext context, AuraDbContext db) =>
{
    // Verify admin token
    var token = context.Request.Headers["Authorization"].FirstOrDefault()?.Replace("Bearer ", "");
    var admin = await db.Users.FirstOrDefaultAsync(u => u.SessionToken == token && u.IsAdmin && u.TokenExpiry > DateTime.UtcNow);

    if (admin == null)
    {
        return Results.Unauthorized();
    }

    var users = await db.Users
        .Where(u => !u.IsAdmin)
        .Include(u => u.Reservations)
        .OrderByDescending(u => u.CreatedAt)
        .Select(u => new {
            u.Id,
            u.Name,
            u.Email,
            u.Phone,
            u.CreatedAt,
            u.LastLoginAt,
            u.LoginCount,
            ReservationCount = u.Reservations.Count,
            IsOnline = u.SessionToken != "" && u.TokenExpiry > DateTime.UtcNow
        })
        .ToListAsync();

    return Results.Ok(users);
});

// Get activity logs (admin only)
app.MapGet("/api/admin/activity-logs", async (HttpContext context, AuraDbContext db, int? limit, int? offset, string? type) =>
{
    // Verify admin token
    var token = context.Request.Headers["Authorization"].FirstOrDefault()?.Replace("Bearer ", "");
    var admin = await db.Users.FirstOrDefaultAsync(u => u.SessionToken == token && u.IsAdmin && u.TokenExpiry > DateTime.UtcNow);

    if (admin == null)
    {
        return Results.Unauthorized();
    }

    var query = db.ActivityLogs.AsQueryable();

    // Filter by type if provided
    if (!string.IsNullOrEmpty(type) && Enum.TryParse<ActivityType>(type, out var activityType))
    {
        query = query.Where(a => a.Type == activityType);
    }

    var total = await query.CountAsync();

    var logs = await query
        .OrderByDescending(a => a.CreatedAt)
        .Skip(offset ?? 0)
        .Take(limit ?? 50)
        .Select(a => new {
            a.Id,
            Type = a.Type.ToString(),
            a.UserId,
            a.UserName,
            a.UserEmail,
            a.Description,
            a.RelatedId,
            a.CreatedAt
        })
        .ToListAsync();

    return Results.Ok(new { total, logs });
});

// ============= RESERVATION ENDPOINTS =============

app.MapGet("/api/reservations", async (HttpContext context, AuraDbContext db) =>
{
    // Verify admin token
    var token = context.Request.Headers["Authorization"].FirstOrDefault()?.Replace("Bearer ", "");
    var admin = await db.Users.FirstOrDefaultAsync(u => u.SessionToken == token && u.IsAdmin && u.TokenExpiry > DateTime.UtcNow);

    if (admin == null)
    {
        return Results.Unauthorized();
    }

    var reservations = await db.Reservations
        .Include(r => r.User)
        .OrderByDescending(r => r.CreatedAt)
        .Select(r => new
        {
            r.Id,
            r.UserId,
            r.Date,
            r.Time,
            r.Guests,
            r.TableNumber,
            Status = r.Status.ToString(),
            r.SpecialRequests,
            r.AdminNotes,
            r.CreatedAt,
            r.UpdatedAt,
            User = new
            {
                r.User.Name,
                r.User.Email,
                r.User.Phone
            }
        })
        .ToListAsync();

    return Results.Ok(reservations);
});

app.MapPost("/api/reservations", async (HttpContext context, ReservationRequest request, AuraDbContext db) =>
{
    // Verify user token
    var token = context.Request.Headers["Authorization"].FirstOrDefault()?.Replace("Bearer ", "");
    var user = await db.Users.FirstOrDefaultAsync(u => u.SessionToken == token && !u.IsAdmin && u.TokenExpiry > DateTime.UtcNow);

    if (user == null)
    {
        return Results.Unauthorized();
    }

    var reservation = new Reservation
    {
        UserId = user.Id,
        Date = request.Date.Kind == DateTimeKind.Unspecified
            ? DateTime.SpecifyKind(request.Date, DateTimeKind.Utc)
            : request.Date,
        Time = request.Time,
        Guests = request.Guests,
        TableNumber = 0,
        Status = ReservationStatus.Pending,
        SpecialRequests = request.SpecialRequests ?? "",
        AdminNotes = "",
        CreatedAt = DateTime.UtcNow,
        UpdatedAt = DateTime.UtcNow
    };

    db.Reservations.Add(reservation);
    await db.SaveChangesAsync();

    // Log activity
    db.ActivityLogs.Add(new ActivityLog
    {
        Type = ActivityType.ReservationCreated,
        UserId = user.Id,
        UserName = user.Name,
        UserEmail = user.Email,
        Description = $"Nova rezervacija: {reservation.Date:dd.MM.yyyy} u {reservation.Time} za {reservation.Guests} osoba",
        RelatedId = reservation.Id,
        CreatedAt = DateTime.UtcNow
    });
    await db.SaveChangesAsync();

    // Return only necessary data (no sensitive user info)
    return Results.Created($"/api/reservations/{reservation.Id}", new {
        reservation.Id,
        reservation.Date,
        reservation.Time,
        reservation.Guests,
        Status = reservation.Status.ToString(),
        reservation.SpecialRequests,
        reservation.CreatedAt
    });
});

// Update reservation (admin only) - change status, table, notes
app.MapPut("/api/reservations/{id}", async (int id, UpdateReservationRequest request, HttpContext context, AuraDbContext db) =>
{
    // Verify admin token
    var token = context.Request.Headers["Authorization"].FirstOrDefault()?.Replace("Bearer ", "");
    var admin = await db.Users.FirstOrDefaultAsync(u => u.SessionToken == token && u.IsAdmin && u.TokenExpiry > DateTime.UtcNow);

    if (admin == null)
    {
        return Results.Unauthorized();
    }

    var reservation = await db.Reservations.Include(r => r.User).FirstOrDefaultAsync(r => r.Id == id);
    if (reservation == null) return Results.NotFound();

    var oldStatus = reservation.Status;

    if (request.Status.HasValue)
        reservation.Status = request.Status.Value;
    if (request.TableNumber.HasValue)
        reservation.TableNumber = request.TableNumber.Value;
    if (request.AdminNotes != null)
        reservation.AdminNotes = request.AdminNotes;

    reservation.UpdatedAt = DateTime.UtcNow;

    // Log activity
    var activityType = request.Status == ReservationStatus.Cancelled
        ? ActivityType.ReservationCancelled
        : ActivityType.ReservationUpdated;

    db.ActivityLogs.Add(new ActivityLog
    {
        Type = activityType,
        UserId = reservation.UserId,
        UserName = reservation.User?.Name ?? "",
        UserEmail = reservation.User?.Email ?? "",
        Description = activityType == ActivityType.ReservationCancelled
            ? $"Rezervacija otkazana: {reservation.Date:dd.MM.yyyy} u {reservation.Time}"
            : $"Rezervacija ažurirana: {oldStatus} -> {reservation.Status}",
        RelatedId = reservation.Id,
        CreatedAt = DateTime.UtcNow
    });

    await db.SaveChangesAsync();

    return Results.Ok(new
    {
        reservation.Id,
        Status = reservation.Status.ToString(),
        reservation.TableNumber,
        reservation.AdminNotes,
        reservation.UpdatedAt
    });
});

app.MapDelete("/api/reservations/{id}", async (int id, HttpContext context, AuraDbContext db) =>
{
    // Verify admin token
    var token = context.Request.Headers["Authorization"].FirstOrDefault()?.Replace("Bearer ", "");
    var admin = await db.Users.FirstOrDefaultAsync(u => u.SessionToken == token && u.IsAdmin && u.TokenExpiry > DateTime.UtcNow);

    if (admin == null)
    {
        return Results.Unauthorized();
    }

    var reservation = await db.Reservations.FindAsync(id);
    if (reservation == null) return Results.NotFound();

    db.Reservations.Remove(reservation);
    await db.SaveChangesAsync();
    return Results.Ok();
});

// Get user's own reservations
app.MapGet("/api/my-reservations", async (HttpContext context, AuraDbContext db) =>
{
    var token = context.Request.Headers["Authorization"].FirstOrDefault()?.Replace("Bearer ", "");
    var user = await db.Users.FirstOrDefaultAsync(u => u.SessionToken == token && !u.IsAdmin && u.TokenExpiry > DateTime.UtcNow);

    if (user == null)
    {
        return Results.Unauthorized();
    }

    var reservations = await db.Reservations
        .Where(r => r.UserId == user.Id)
        .OrderByDescending(r => r.Date)
        .Select(r => new
        {
            r.Id,
            r.Date,
            r.Time,
            r.Guests,
            r.TableNumber,
            Status = r.Status.ToString(),
            r.SpecialRequests,
            r.CreatedAt
        })
        .ToListAsync();

    return Results.Ok(reservations);
});

// ============= MENU ENDPOINTS =============

// Get all menu items (public)
app.MapGet("/api/menu", async (AuraDbContext db) =>
{
    var items = await db.MenuItems
        .Where(m => m.IsAvailable)
        .OrderBy(m => m.Category)
        .ThenBy(m => m.SortOrder)
        .Select(m => new
        {
            m.Id,
            m.Name,
            m.Description,
            m.Price,
            Category = m.Category.ToString(),
            m.ImageUrl,
            m.IsVegetarian,
            m.IsVegan,
            m.IsGlutenFree,
            m.Allergens
        })
        .ToListAsync();

    return Results.Ok(items);
});

// Get all menu items including unavailable (admin)
app.MapGet("/api/admin/menu", async (HttpContext context, AuraDbContext db) =>
{
    var token = context.Request.Headers["Authorization"].FirstOrDefault()?.Replace("Bearer ", "");
    var admin = await db.Users.FirstOrDefaultAsync(u => u.SessionToken == token && u.IsAdmin && u.TokenExpiry > DateTime.UtcNow);
    if (admin == null) return Results.Unauthorized();

    var items = await db.MenuItems
        .OrderBy(m => m.Category)
        .ThenBy(m => m.SortOrder)
        .ToListAsync();

    return Results.Ok(items);
});

// Create menu item (admin)
app.MapPost("/api/admin/menu", async (MenuItemRequest request, HttpContext context, AuraDbContext db) =>
{
    var token = context.Request.Headers["Authorization"].FirstOrDefault()?.Replace("Bearer ", "");
    var admin = await db.Users.FirstOrDefaultAsync(u => u.SessionToken == token && u.IsAdmin && u.TokenExpiry > DateTime.UtcNow);
    if (admin == null) return Results.Unauthorized();

    var item = new MenuItem
    {
        Name = request.Name,
        Description = request.Description,
        Price = request.Price,
        Category = request.Category,
        ImageUrl = request.ImageUrl,
        IsAvailable = request.IsAvailable,
        IsVegetarian = request.IsVegetarian,
        IsVegan = request.IsVegan,
        IsGlutenFree = request.IsGlutenFree,
        Allergens = request.Allergens,
        SortOrder = request.SortOrder,
        CreatedAt = DateTime.UtcNow
    };

    db.MenuItems.Add(item);
    await db.SaveChangesAsync();
    return Results.Created($"/api/menu/{item.Id}", item);
});

// Update menu item (admin)
app.MapPut("/api/admin/menu/{id}", async (int id, MenuItemRequest request, HttpContext context, AuraDbContext db) =>
{
    var token = context.Request.Headers["Authorization"].FirstOrDefault()?.Replace("Bearer ", "");
    var admin = await db.Users.FirstOrDefaultAsync(u => u.SessionToken == token && u.IsAdmin && u.TokenExpiry > DateTime.UtcNow);
    if (admin == null) return Results.Unauthorized();

    var item = await db.MenuItems.FindAsync(id);
    if (item == null) return Results.NotFound();

    item.Name = request.Name;
    item.Description = request.Description;
    item.Price = request.Price;
    item.Category = request.Category;
    item.ImageUrl = request.ImageUrl;
    item.IsAvailable = request.IsAvailable;
    item.IsVegetarian = request.IsVegetarian;
    item.IsVegan = request.IsVegan;
    item.IsGlutenFree = request.IsGlutenFree;
    item.Allergens = request.Allergens;
    item.SortOrder = request.SortOrder;
    item.UpdatedAt = DateTime.UtcNow;

    await db.SaveChangesAsync();
    return Results.Ok(item);
});

// Delete menu item (admin)
app.MapDelete("/api/admin/menu/{id}", async (int id, HttpContext context, AuraDbContext db) =>
{
    var token = context.Request.Headers["Authorization"].FirstOrDefault()?.Replace("Bearer ", "");
    var admin = await db.Users.FirstOrDefaultAsync(u => u.SessionToken == token && u.IsAdmin && u.TokenExpiry > DateTime.UtcNow);
    if (admin == null) return Results.Unauthorized();

    var item = await db.MenuItems.FindAsync(id);
    if (item == null) return Results.NotFound();

    db.MenuItems.Remove(item);
    await db.SaveChangesAsync();
    return Results.Ok();
});

// ============= SCHEDULE ENDPOINTS =============

// Get weekly schedule (public)
app.MapGet("/api/schedule", async (AuraDbContext db) =>
{
    var schedule = await db.DaySchedules
        .Include(d => d.TimeSlots.Where(t => t.IsEnabled))
        .OrderBy(d => d.DayOfWeek)
        .Select(d => new
        {
            d.Id,
            DayOfWeek = d.DayOfWeek.ToString(),
            d.IsOpen,
            d.OpenTime,
            d.CloseTime,
            TimeSlots = d.TimeSlots.Select(t => new { t.Time, t.MaxReservations })
        })
        .ToListAsync();

    return Results.Ok(schedule);
});

// Get available slots for a specific date (public)
app.MapGet("/api/schedule/available/{date}", async (DateTime date, AuraDbContext db) =>
{
    // Check for date override first
    var dateOnly = date.Date;
    var utcDate = DateTime.SpecifyKind(dateOnly, DateTimeKind.Utc);

    var dateOverride = await db.DateOverrides.FirstOrDefaultAsync(d => d.Date.Date == utcDate.Date);
    if (dateOverride?.IsClosed == true)
    {
        return Results.Ok(new { IsClosed = true, Reason = dateOverride.Reason, Slots = Array.Empty<object>(), AllSlots = Array.Empty<object>() });
    }

    // Get day schedule
    var dayOfWeek = (DayOfWeekEnum)((int)date.DayOfWeek == 0 ? 6 : (int)date.DayOfWeek - 1); // Convert to our enum
    var daySchedule = await db.DaySchedules
        .Include(d => d.TimeSlots)
        .FirstOrDefaultAsync(d => d.DayOfWeek == dayOfWeek);

    if (daySchedule == null || !daySchedule.IsOpen)
    {
        return Results.Ok(new { IsClosed = true, Reason = "Zatvoreno", Slots = Array.Empty<object>(), AllSlots = Array.Empty<object>() });
    }

    // Get existing reservations for that date
    var existingReservations = await db.Reservations
        .Where(r => r.Date.Date == utcDate.Date && r.Status != ReservationStatus.Cancelled)
        .GroupBy(r => r.Time)
        .Select(g => new { Time = g.Key, Count = g.Count() })
        .ToListAsync();

    // Provjeri je li danas - ako da, filtriraj prošle termine
    var now = DateTime.Now;
    var todayLocal = DateTime.Today;
    var isToday = dateOnly == todayLocal;
    var currentHour = now.Hour;

    // Odredi radno vrijeme za taj dan (uzmi override ako postoji)
    var effectiveOpenTime = dateOverride?.OpenTime ?? daySchedule.OpenTime ?? "12:00";
    var effectiveCloseTime = dateOverride?.CloseTime ?? daySchedule.CloseTime ?? "23:00";

    // Parsiraj sate za filtriranje
    int.TryParse(effectiveOpenTime.Split(':')[0], out int openHour);
    int.TryParse(effectiveCloseTime.Split(':')[0], out int closeHour);

    // Return ALL slots (including full ones) so frontend can show them as crossed out
    // Ali filtriraj prema radnom vremenu i ako je danas, filtriraj prošle termine
    var allSlots = daySchedule.TimeSlots
        .Where(t => t.IsEnabled)
        .Where(t => {
            // Parsiraj sat iz vremena (npr. "14:00" -> 14)
            if (!int.TryParse(t.Time.Split(':')[0], out int slotHour)) return true;

            // Filtriraj slotove izvan radnog vremena
            if (slotHour < openHour || slotHour >= closeHour) return false;

            // Ako je danas, filtriraj prošle termine
            if (isToday && slotHour <= currentHour) return false;

            return true;
        })
        .OrderBy(t => t.Time)
        .Select(t =>
        {
            var reserved = existingReservations.FirstOrDefault(r => r.Time == t.Time)?.Count ?? 0;
            return new
            {
                t.Time,
                Available = t.MaxReservations - reserved,
                t.MaxReservations
            };
        })
        .ToList();

    // Also return only available slots for backward compatibility
    var availableSlots = allSlots.Where(s => s.Available > 0).ToList();

    return Results.Ok(new
    {
        IsClosed = false,
        OpenTime = effectiveOpenTime,
        CloseTime = effectiveCloseTime,
        Slots = availableSlots,
        AllSlots = allSlots
    });
});

// Get calendar availability for a date range (public)
// Returns status for each day: "available", "limited", "full", "closed"
app.MapGet("/api/schedule/calendar/{startDate}/{endDate}", async (DateTime startDate, DateTime endDate, AuraDbContext db) =>
{
    var result = new List<object>();
    var start = DateTime.SpecifyKind(startDate.Date, DateTimeKind.Utc);
    var end = DateTime.SpecifyKind(endDate.Date, DateTimeKind.Utc);

    // Get all day schedules with time slots
    var daySchedules = await db.DaySchedules
        .Include(d => d.TimeSlots)
        .ToListAsync();

    // Get all date overrides in range
    var dateOverrides = await db.DateOverrides
        .Where(d => d.Date >= start && d.Date <= end)
        .ToListAsync();

    // Get all reservations in range (excluding cancelled)
    var reservations = await db.Reservations
        .Where(r => r.Date >= start && r.Date <= end && r.Status != ReservationStatus.Cancelled)
        .ToListAsync();

    for (var date = start; date <= end; date = date.AddDays(1))
    {
        // Check for date override first
        var dateOverride = dateOverrides.FirstOrDefault(d => d.Date.Date == date.Date);
        if (dateOverride?.IsClosed == true)
        {
            result.Add(new { Date = date.ToString("yyyy-MM-dd"), Status = "closed", AvailableSlots = 0, TotalSlots = 0 });
            continue;
        }

        // Get day schedule
        var dayOfWeek = (DayOfWeekEnum)((int)date.DayOfWeek == 0 ? 6 : (int)date.DayOfWeek - 1);
        var daySchedule = daySchedules.FirstOrDefault(d => d.DayOfWeek == dayOfWeek);

        if (daySchedule == null || !daySchedule.IsOpen)
        {
            result.Add(new { Date = date.ToString("yyyy-MM-dd"), Status = "closed", AvailableSlots = 0, TotalSlots = 0 });
            continue;
        }

        // Odredi radno vrijeme (koristi override ako postoji skraćeno radno vrijeme)
        var effectiveOpenTime = dateOverride?.OpenTime ?? daySchedule.OpenTime ?? "12:00";
        var effectiveCloseTime = dateOverride?.CloseTime ?? daySchedule.CloseTime ?? "23:00";
        int.TryParse(effectiveOpenTime.Split(':')[0], out int openHour);
        int.TryParse(effectiveCloseTime.Split(':')[0], out int closeHour);

        // Count reservations for this date
        var dayReservations = reservations.Where(r => r.Date.Date == date.Date).ToList();

        // Filtriraj slotove prema radnom vremenu
        var validSlots = daySchedule.TimeSlots
            .Where(t => t.IsEnabled)
            .Where(t => {
                if (!int.TryParse(t.Time.Split(':')[0], out int slotHour)) return true;
                return slotHour >= openHour && slotHour < closeHour;
            })
            .ToList();

        var totalSlots = validSlots.Count;

        // Count available slots
        var availableSlots = 0;
        foreach (var slot in validSlots)
        {
            var slotReservations = dayReservations.Count(r => r.Time == slot.Time);
            if (slotReservations < slot.MaxReservations)
            {
                availableSlots++;
            }
        }

        // Determine status
        // "limited" = više od pola termina zauzeto (manje od pola slobodno)
        string status;
        var takenSlots = totalSlots - availableSlots;
        if (availableSlots == 0)
            status = "full";
        else if (takenSlots > totalSlots / 2)  // Više od pola zauzeto = žuto
            status = "limited";
        else
            status = "available";

        result.Add(new { Date = date.ToString("yyyy-MM-dd"), Status = status, AvailableSlots = availableSlots, TotalSlots = totalSlots });
    }

    return Results.Ok(result);
});

// Update day schedule (admin)
app.MapPut("/api/admin/schedule/{dayOfWeek}", async (DayOfWeekEnum dayOfWeek, DayScheduleRequest request, HttpContext context, AuraDbContext db) =>
{
    var token = context.Request.Headers["Authorization"].FirstOrDefault()?.Replace("Bearer ", "");
    var admin = await db.Users.FirstOrDefaultAsync(u => u.SessionToken == token && u.IsAdmin && u.TokenExpiry > DateTime.UtcNow);
    if (admin == null) return Results.Unauthorized();

    var schedule = await db.DaySchedules.FirstOrDefaultAsync(d => d.DayOfWeek == dayOfWeek);
    if (schedule == null)
    {
        schedule = new DaySchedule { DayOfWeek = dayOfWeek };
        db.DaySchedules.Add(schedule);
    }

    schedule.IsOpen = request.IsOpen;
    schedule.OpenTime = request.OpenTime;
    schedule.CloseTime = request.CloseTime;
    schedule.UpdatedAt = DateTime.UtcNow;

    await db.SaveChangesAsync();
    return Results.Ok(schedule);
});

// Add/Update time slot (admin)
app.MapPost("/api/admin/schedule/{dayOfWeek}/slots", async (DayOfWeekEnum dayOfWeek, TimeSlotRequest request, HttpContext context, AuraDbContext db) =>
{
    var token = context.Request.Headers["Authorization"].FirstOrDefault()?.Replace("Bearer ", "");
    var admin = await db.Users.FirstOrDefaultAsync(u => u.SessionToken == token && u.IsAdmin && u.TokenExpiry > DateTime.UtcNow);
    if (admin == null) return Results.Unauthorized();

    var schedule = await db.DaySchedules.FirstOrDefaultAsync(d => d.DayOfWeek == dayOfWeek);
    if (schedule == null) return Results.NotFound("Dan nije pronađen");

    var existingSlot = await db.TimeSlots.FirstOrDefaultAsync(t => t.DayScheduleId == schedule.Id && t.Time == request.Time);
    if (existingSlot != null)
    {
        existingSlot.MaxReservations = request.MaxReservations;
        existingSlot.IsEnabled = request.IsEnabled;
    }
    else
    {
        var slot = new TimeSlot
        {
            DayScheduleId = schedule.Id,
            Time = request.Time,
            MaxReservations = request.MaxReservations,
            IsEnabled = request.IsEnabled
        };
        db.TimeSlots.Add(slot);
    }

    await db.SaveChangesAsync();
    return Results.Ok();
});

// Delete time slot (admin)
app.MapDelete("/api/admin/schedule/slots/{id}", async (int id, HttpContext context, AuraDbContext db) =>
{
    var token = context.Request.Headers["Authorization"].FirstOrDefault()?.Replace("Bearer ", "");
    var admin = await db.Users.FirstOrDefaultAsync(u => u.SessionToken == token && u.IsAdmin && u.TokenExpiry > DateTime.UtcNow);
    if (admin == null) return Results.Unauthorized();

    var slot = await db.TimeSlots.FindAsync(id);
    if (slot == null) return Results.NotFound();

    db.TimeSlots.Remove(slot);
    await db.SaveChangesAsync();
    return Results.Ok();
});

// ============= DATE OVERRIDE ENDPOINTS =============

// Get all date overrides (admin)
app.MapGet("/api/admin/date-overrides", async (HttpContext context, AuraDbContext db) =>
{
    var token = context.Request.Headers["Authorization"].FirstOrDefault()?.Replace("Bearer ", "");
    var admin = await db.Users.FirstOrDefaultAsync(u => u.SessionToken == token && u.IsAdmin && u.TokenExpiry > DateTime.UtcNow);
    if (admin == null) return Results.Unauthorized();

    var overrides = await db.DateOverrides
        .OrderBy(d => d.Date)
        .ToListAsync();

    return Results.Ok(overrides);
});

// Create date override (admin)
app.MapPost("/api/admin/date-overrides", async (DateOverrideRequest request, HttpContext context, AuraDbContext db) =>
{
    var token = context.Request.Headers["Authorization"].FirstOrDefault()?.Replace("Bearer ", "");
    var admin = await db.Users.FirstOrDefaultAsync(u => u.SessionToken == token && u.IsAdmin && u.TokenExpiry > DateTime.UtcNow);
    if (admin == null) return Results.Unauthorized();

    var dateOverride = new DateOverride
    {
        Date = DateTime.SpecifyKind(request.Date.Date, DateTimeKind.Utc),
        IsClosed = request.IsClosed,
        OpenTime = request.OpenTime,
        CloseTime = request.CloseTime,
        Reason = request.Reason,
        CreatedAt = DateTime.UtcNow
    };

    db.DateOverrides.Add(dateOverride);
    await db.SaveChangesAsync();
    return Results.Created($"/api/admin/date-overrides/{dateOverride.Id}", dateOverride);
});

// Delete date override (admin)
app.MapDelete("/api/admin/date-overrides/{id}", async (int id, HttpContext context, AuraDbContext db) =>
{
    var token = context.Request.Headers["Authorization"].FirstOrDefault()?.Replace("Bearer ", "");
    var admin = await db.Users.FirstOrDefaultAsync(u => u.SessionToken == token && u.IsAdmin && u.TokenExpiry > DateTime.UtcNow);
    if (admin == null) return Results.Unauthorized();

    var dateOverride = await db.DateOverrides.FindAsync(id);
    if (dateOverride == null) return Results.NotFound();

    db.DateOverrides.Remove(dateOverride);
    await db.SaveChangesAsync();
    return Results.Ok();
});

// ============= ORDER ENDPOINTS =============

// Create order (authenticated user)
app.MapPost("/api/orders", async (HttpContext context, OrderRequest request, AuraDbContext db) =>
{
    var token = context.Request.Headers["Authorization"].FirstOrDefault()?.Replace("Bearer ", "");
    var user = await db.Users.FirstOrDefaultAsync(u => u.SessionToken == token && !u.IsAdmin && u.TokenExpiry > DateTime.UtcNow);

    if (user == null)
    {
        return Results.Unauthorized();
    }

    if (request.Items == null || request.Items.Count == 0)
    {
        return Results.BadRequest(new { error = "Košarica je prazna" });
    }

    // Calculate total and create order items
    var orderItems = new List<OrderItem>();
    decimal totalAmount = 0;

    foreach (var item in request.Items)
    {
        var menuItem = await db.MenuItems.FindAsync(item.MenuItemId);
        if (menuItem == null || !menuItem.IsAvailable)
        {
            return Results.BadRequest(new { error = $"Artikl nije dostupan" });
        }

        var orderItem = new OrderItem
        {
            MenuItemId = menuItem.Id,
            MenuItemName = menuItem.Name,
            Price = menuItem.Price,
            Quantity = item.Quantity,
            Notes = item.Notes ?? ""
        };
        orderItems.Add(orderItem);
        totalAmount += menuItem.Price * item.Quantity;
    }

    var order = new Order
    {
        UserId = user.Id,
        Status = OrderStatus.Pending,
        DeliveryAddress = request.DeliveryAddress,
        DeliveryCity = request.DeliveryCity,
        DeliveryPostalCode = request.DeliveryPostalCode,
        Phone = request.Phone ?? user.Phone,
        Notes = request.Notes ?? "",
        TotalAmount = totalAmount,
        CreatedAt = DateTime.UtcNow,
        UpdatedAt = DateTime.UtcNow,
        Items = orderItems
    };

    db.Orders.Add(order);
    await db.SaveChangesAsync();

    // Log activity
    db.ActivityLogs.Add(new ActivityLog
    {
        Type = ActivityType.OrderCreated,
        UserId = user.Id,
        UserName = user.Name,
        UserEmail = user.Email,
        Description = $"Nova narudžba: {orderItems.Count} artikala, ukupno {totalAmount:F2} EUR",
        RelatedId = order.Id,
        CreatedAt = DateTime.UtcNow
    });
    await db.SaveChangesAsync();

    return Results.Created($"/api/orders/{order.Id}", new
    {
        order.Id,
        Status = order.Status.ToString(),
        order.TotalAmount,
        order.CreatedAt,
        ItemCount = orderItems.Count
    });
});

// Guest order (no authentication required)
app.MapPost("/api/orders/guest", async (GuestOrderRequest request, AuraDbContext db) =>
{
    if (request.Items == null || request.Items.Count == 0)
    {
        return Results.BadRequest(new { error = "Košarica je prazna" });
    }

    if (string.IsNullOrWhiteSpace(request.CustomerName))
    {
        return Results.BadRequest(new { error = "Ime je obavezno" });
    }

    if (string.IsNullOrWhiteSpace(request.Phone))
    {
        return Results.BadRequest(new { error = "Broj telefona je obavezan" });
    }

    if (string.IsNullOrWhiteSpace(request.DeliveryAddress))
    {
        return Results.BadRequest(new { error = "Adresa je obavezna" });
    }

    // Calculate total and create order items
    var orderItems = new List<OrderItem>();
    decimal totalAmount = 0;

    foreach (var item in request.Items)
    {
        var menuItem = await db.MenuItems.FindAsync(item.MenuItemId);
        if (menuItem == null || !menuItem.IsAvailable)
        {
            return Results.BadRequest(new { error = $"Artikl nije dostupan" });
        }

        var orderItem = new OrderItem
        {
            MenuItemId = menuItem.Id,
            MenuItemName = menuItem.Name,
            Price = menuItem.Price,
            Quantity = item.Quantity,
            Notes = item.Notes ?? ""
        };
        orderItems.Add(orderItem);
        totalAmount += menuItem.Price * item.Quantity;
    }

    var order = new Order
    {
        UserId = null,
        CustomerName = request.CustomerName,
        Status = OrderStatus.Pending,
        DeliveryAddress = request.DeliveryAddress,
        DeliveryCity = "",
        DeliveryPostalCode = "",
        Phone = request.Phone,
        Notes = request.Notes ?? "",
        TotalAmount = totalAmount,
        CreatedAt = DateTime.UtcNow,
        UpdatedAt = DateTime.UtcNow,
        Items = orderItems
    };

    db.Orders.Add(order);
    await db.SaveChangesAsync();

    // Log activity
    db.ActivityLogs.Add(new ActivityLog
    {
        Type = ActivityType.OrderCreated,
        UserId = null,
        UserName = request.CustomerName,
        UserEmail = "gost",
        Description = $"Nova gost narudžba: {orderItems.Count} artikala, ukupno {totalAmount:F2} EUR",
        RelatedId = order.Id,
        CreatedAt = DateTime.UtcNow
    });
    await db.SaveChangesAsync();

    return Results.Created($"/api/orders/{order.Id}", new
    {
        order.Id,
        Status = order.Status.ToString(),
        order.TotalAmount,
        order.CreatedAt,
        ItemCount = orderItems.Count
    });
});

// Get user's orders
app.MapGet("/api/my-orders", async (HttpContext context, AuraDbContext db) =>
{
    var token = context.Request.Headers["Authorization"].FirstOrDefault()?.Replace("Bearer ", "");
    var user = await db.Users.FirstOrDefaultAsync(u => u.SessionToken == token && !u.IsAdmin && u.TokenExpiry > DateTime.UtcNow);

    if (user == null)
    {
        return Results.Unauthorized();
    }

    var orders = await db.Orders
        .Where(o => o.UserId == user.Id)
        .Include(o => o.Items)
        .OrderByDescending(o => o.CreatedAt)
        .Select(o => new
        {
            o.Id,
            Status = o.Status.ToString(),
            o.DeliveryAddress,
            o.DeliveryCity,
            o.TotalAmount,
            o.CreatedAt,
            Items = o.Items.Select(i => new
            {
                i.MenuItemName,
                i.Price,
                i.Quantity,
                i.Notes
            })
        })
        .ToListAsync();

    return Results.Ok(orders);
});

// Get all orders (admin)
app.MapGet("/api/orders", async (HttpContext context, AuraDbContext db) =>
{
    var token = context.Request.Headers["Authorization"].FirstOrDefault()?.Replace("Bearer ", "");
    var admin = await db.Users.FirstOrDefaultAsync(u => u.SessionToken == token && u.IsAdmin && u.TokenExpiry > DateTime.UtcNow);

    if (admin == null)
    {
        return Results.Unauthorized();
    }

    var orders = await db.Orders
        .Include(o => o.User)
        .Include(o => o.Items)
        .OrderByDescending(o => o.CreatedAt)
        .Select(o => new
        {
            o.Id,
            o.UserId,
            o.CustomerName,
            Status = o.Status.ToString(),
            o.DeliveryAddress,
            o.DeliveryCity,
            o.DeliveryPostalCode,
            o.Phone,
            o.Notes,
            o.TotalAmount,
            o.CreatedAt,
            o.UpdatedAt,
            User = o.User != null ? new
            {
                o.User.Name,
                o.User.Email,
                o.User.Phone
            } : null,
            Items = o.Items.Select(i => new
            {
                i.Id,
                i.MenuItemName,
                i.Price,
                i.Quantity,
                i.Notes
            })
        })
        .ToListAsync();

    return Results.Ok(orders);
});

// Update order status (admin)
app.MapPut("/api/orders/{id}", async (int id, UpdateOrderRequest request, HttpContext context, AuraDbContext db) =>
{
    var token = context.Request.Headers["Authorization"].FirstOrDefault()?.Replace("Bearer ", "");
    var admin = await db.Users.FirstOrDefaultAsync(u => u.SessionToken == token && u.IsAdmin && u.TokenExpiry > DateTime.UtcNow);

    if (admin == null)
    {
        return Results.Unauthorized();
    }

    var order = await db.Orders.Include(o => o.User).FirstOrDefaultAsync(o => o.Id == id);
    if (order == null) return Results.NotFound();

    var oldStatus = order.Status;

    if (request.Status.HasValue)
        order.Status = request.Status.Value;
    if (request.Notes != null)
        order.Notes = request.Notes;

    order.UpdatedAt = DateTime.UtcNow;

    // Log activity
    var activityType = request.Status == OrderStatus.Cancelled
        ? ActivityType.OrderCancelled
        : ActivityType.OrderUpdated;

    db.ActivityLogs.Add(new ActivityLog
    {
        Type = activityType,
        UserId = order.UserId,
        UserName = order.User?.Name ?? "",
        UserEmail = order.User?.Email ?? "",
        Description = activityType == ActivityType.OrderCancelled
            ? $"Narudžba #{order.Id} otkazana"
            : $"Narudžba #{order.Id} ažurirana: {oldStatus} -> {order.Status}",
        RelatedId = order.Id,
        CreatedAt = DateTime.UtcNow
    });

    await db.SaveChangesAsync();

    return Results.Ok(new
    {
        order.Id,
        Status = order.Status.ToString(),
        order.UpdatedAt
    });
});

// Delete order (admin)
app.MapDelete("/api/orders/{id}", async (int id, HttpContext context, AuraDbContext db) =>
{
    var token = context.Request.Headers["Authorization"].FirstOrDefault()?.Replace("Bearer ", "");
    var admin = await db.Users.FirstOrDefaultAsync(u => u.SessionToken == token && u.IsAdmin && u.TokenExpiry > DateTime.UtcNow);

    if (admin == null)
    {
        return Results.Unauthorized();
    }

    var order = await db.Orders.FindAsync(id);
    if (order == null) return Results.NotFound();

    db.Orders.Remove(order);
    await db.SaveChangesAsync();
    return Results.Ok();
});

// SPA fallback for Angular app and desktop index - must be after all other endpoints
app.MapFallback(async context =>
{
    var path = context.Request.Path.Value?.ToLower() ?? "";
    if (path.StartsWith("/mobile-angular"))
    {
        // Serve Angular SPA for mobile
        context.Response.ContentType = "text/html";
        await context.Response.SendFileAsync(
            Path.Combine(app.Environment.WebRootPath, "mobile-angular", "index.html")
        );
    }
    else if (!path.Contains("."))
    {
        // Serve desktop index.html for non-file paths
        var indexPath = Path.Combine(app.Environment.WebRootPath, "index.html");
        if (File.Exists(indexPath))
        {
            context.Response.ContentType = "text/html";
            await context.Response.SendFileAsync(indexPath);
        }
        else
        {
            context.Response.StatusCode = 404;
        }
    }
    else
    {
        context.Response.StatusCode = 404;
    }
});

app.Run();

// ============= HELPER FUNCTIONS =============
static string GenerateToken()
{
    var bytes = new byte[32];
    using var rng = RandomNumberGenerator.Create();
    rng.GetBytes(bytes);
    return Convert.ToBase64String(bytes);
}

// ============= REQUEST MODELS =============
public class RegisterRequest
{
    public string Name { get; set; } = "";
    public string Email { get; set; } = "";
    public string Phone { get; set; } = "";
    public string Password { get; set; } = "";
}

public class LoginRequest
{
    public string Email { get; set; } = "";
    public string Password { get; set; } = "";
}

public class ReservationRequest
{
    public DateTime Date { get; set; }
    public string Time { get; set; } = "";
    public int Guests { get; set; }
    public string? SpecialRequests { get; set; }
}

public class UpdateReservationRequest
{
    public ReservationStatus? Status { get; set; }
    public int? TableNumber { get; set; }
    public string AdminNotes { get; set; } = "";
}

public class MenuItemRequest
{
    public string Name { get; set; } = "";
    public string Description { get; set; } = "";
    public decimal Price { get; set; }
    public MenuCategory Category { get; set; }
    public string ImageUrl { get; set; } = "";
    public bool IsAvailable { get; set; } = true;
    public bool IsVegetarian { get; set; }
    public bool IsVegan { get; set; }
    public bool IsGlutenFree { get; set; }
    public string Allergens { get; set; } = "";
    public int SortOrder { get; set; }
}

public class DayScheduleRequest
{
    public bool IsOpen { get; set; }
    public string OpenTime { get; set; } = "12:00";
    public string CloseTime { get; set; } = "22:00";
}

public class TimeSlotRequest
{
    public string Time { get; set; } = "";
    public int MaxReservations { get; set; } = 10;
    public bool IsEnabled { get; set; } = true;
}

public class DateOverrideRequest
{
    public DateTime Date { get; set; }
    public bool IsClosed { get; set; }
    public string OpenTime { get; set; } = "";
    public string CloseTime { get; set; } = "";
    public string Reason { get; set; } = "";
}

public class OrderRequest
{
    public string DeliveryAddress { get; set; } = "";
    public string DeliveryCity { get; set; } = "";
    public string DeliveryPostalCode { get; set; } = "";
    public string Phone { get; set; } = "";
    public string Notes { get; set; } = "";
    public List<OrderItemRequest> Items { get; set; } = new();
}

public class OrderItemRequest
{
    public int MenuItemId { get; set; }
    public int Quantity { get; set; }
    public string Notes { get; set; } = "";
}

public class UpdateOrderRequest
{
    public OrderStatus? Status { get; set; }
    public string? Notes { get; set; }
}

public class GuestOrderRequest
{
    public string CustomerName { get; set; } = "";
    public string DeliveryAddress { get; set; } = "";
    public string Phone { get; set; } = "";
    public string Notes { get; set; } = "";
    public List<OrderItemRequest> Items { get; set; } = new();
}

// ============= MODELS =============
public class User
{
    public int Id { get; set; }
    public string Name { get; set; } = "";
    public string Email { get; set; } = "";
    public string Phone { get; set; } = "";
    public string PasswordHash { get; set; } = "";
    public bool IsAdmin { get; set; }
    public string SessionToken { get; set; } = "";
    public DateTime TokenExpiry { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
    public DateTime LastLoginAt { get; set; }
    public int LoginCount { get; set; } = 0;

    // Navigation property
    public ICollection<Reservation> Reservations { get; set; } = new List<Reservation>();
}

public enum ReservationStatus
{
    Pending = 0,
    Confirmed = 1,
    Cancelled = 2,
    Completed = 3
}

public class Reservation
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public DateTime Date { get; set; }
    public string Time { get; set; } = "";
    public int Guests { get; set; }
    public int TableNumber { get; set; } = 0;  // 0 = not assigned yet
    public ReservationStatus Status { get; set; } = ReservationStatus.Pending;
    public string SpecialRequests { get; set; } = "";
    public string AdminNotes { get; set; } = "";
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }

    // Navigation property
    public User User { get; set; } = null!;
}

// ============= MENU MODELS =============
public enum MenuCategory
{
    Appetizer = 0,    // Predjela
    Soup = 1,         // Juhe
    Salad = 2,        // Salate
    Pasta = 3,        // Tjestenina i rižoti
    Fish = 4,         // Ribe i plodovi mora
    Meat = 5,         // Meso
    Dessert = 6,      // Deserti
    Beverage = 7,     // Pića
    Special = 8       // Specijalitet dana
}

public class MenuItem
{
    public int Id { get; set; }
    public string Name { get; set; } = "";
    public string Description { get; set; } = "";
    public decimal Price { get; set; }
    public MenuCategory Category { get; set; }
    public string ImageUrl { get; set; } = "";
    public bool IsAvailable { get; set; } = true;
    public bool IsVegetarian { get; set; }
    public bool IsVegan { get; set; }
    public bool IsGlutenFree { get; set; }
    public string Allergens { get; set; } = "";
    public int SortOrder { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
}

// ============= SCHEDULE MODELS =============
public enum DayOfWeekEnum
{
    Monday = 0,
    Tuesday = 1,
    Wednesday = 2,
    Thursday = 3,
    Friday = 4,
    Saturday = 5,
    Sunday = 6
}

public class DaySchedule
{
    public int Id { get; set; }
    public DayOfWeekEnum DayOfWeek { get; set; }
    public bool IsOpen { get; set; } = true;
    public string OpenTime { get; set; } = "12:00";
    public string CloseTime { get; set; } = "22:00";
    public DateTime UpdatedAt { get; set; }

    // Navigation property
    public ICollection<TimeSlot> TimeSlots { get; set; } = new List<TimeSlot>();
}

public class TimeSlot
{
    public int Id { get; set; }
    public int DayScheduleId { get; set; }
    public string Time { get; set; } = "";      // "12:00", "12:30", "13:00"...
    public int MaxReservations { get; set; } = 10;
    public bool IsEnabled { get; set; } = true;

    // Navigation property
    public DaySchedule DaySchedule { get; set; } = null!;
}

// Special date override (holidays, events)
public class DateOverride
{
    public int Id { get; set; }
    public DateTime Date { get; set; }
    public bool IsClosed { get; set; }
    public string OpenTime { get; set; } = "";
    public string CloseTime { get; set; } = "";
    public string Reason { get; set; } = "";  // "Božić", "Privatna zabava"
    public DateTime CreatedAt { get; set; }
}

// ============= ACTIVITY LOG =============
public enum ActivityType
{
    UserRegistered = 0,
    UserLogin = 1,
    AdminLogin = 2,
    UserLogout = 3,
    ReservationCreated = 4,
    ReservationUpdated = 5,
    ReservationCancelled = 6,
    OrderCreated = 7,
    OrderUpdated = 8,
    OrderCancelled = 9
}

public class ActivityLog
{
    public int Id { get; set; }
    public ActivityType Type { get; set; }
    public int? UserId { get; set; }
    public string UserName { get; set; } = "";
    public string UserEmail { get; set; } = "";
    public string Description { get; set; } = "";
    public int? RelatedId { get; set; }  // ReservationId, etc.
    public DateTime CreatedAt { get; set; }

    // Navigation property
    public User? User { get; set; }
}

// ============= ORDER MODELS =============
public enum OrderStatus
{
    Pending = 0,
    Confirmed = 1,
    Preparing = 2,
    OutForDelivery = 3,
    Delivered = 4,
    Cancelled = 5
}

public class Order
{
    public int Id { get; set; }
    public int? UserId { get; set; }  // Nullable for guest orders
    public string? CustomerName { get; set; }  // For guest orders
    public OrderStatus Status { get; set; } = OrderStatus.Pending;
    public string DeliveryAddress { get; set; } = "";
    public string DeliveryCity { get; set; } = "";
    public string DeliveryPostalCode { get; set; } = "";
    public string Phone { get; set; } = "";
    public string Notes { get; set; } = "";
    public decimal TotalAmount { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }

    // Navigation properties
    public User? User { get; set; }
    public ICollection<OrderItem> Items { get; set; } = new List<OrderItem>();
}

public class OrderItem
{
    public int Id { get; set; }
    public int OrderId { get; set; }
    public int MenuItemId { get; set; }
    public string MenuItemName { get; set; } = "";  // Snapshot of name at order time
    public decimal Price { get; set; }  // Snapshot of price at order time
    public int Quantity { get; set; }
    public string Notes { get; set; } = "";

    // Navigation properties
    public Order Order { get; set; } = null!;
    public MenuItem MenuItem { get; set; } = null!;
}

// ============= DATABASE =============
public class AuraDbContext : DbContext
{
    public AuraDbContext(DbContextOptions<AuraDbContext> options) : base(options) { }

    public DbSet<User> Users { get; set; }
    public DbSet<Reservation> Reservations { get; set; }
    public DbSet<MenuItem> MenuItems { get; set; }
    public DbSet<DaySchedule> DaySchedules { get; set; }
    public DbSet<TimeSlot> TimeSlots { get; set; }
    public DbSet<DateOverride> DateOverrides { get; set; }
    public DbSet<ActivityLog> ActivityLogs { get; set; }
    public DbSet<Order> Orders { get; set; }
    public DbSet<OrderItem> OrderItems { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        // ===== USER & RESERVATION =====
        modelBuilder.Entity<Reservation>()
            .HasOne(r => r.User)
            .WithMany(u => u.Reservations)
            .HasForeignKey(r => r.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<Reservation>()
            .HasIndex(r => r.Date);

        modelBuilder.Entity<Reservation>()
            .HasIndex(r => r.Status);

        modelBuilder.Entity<User>()
            .HasIndex(u => u.Email)
            .IsUnique();

        // ===== MENU =====
        modelBuilder.Entity<MenuItem>()
            .HasIndex(m => m.Category);

        modelBuilder.Entity<MenuItem>()
            .HasIndex(m => m.IsAvailable);

        modelBuilder.Entity<MenuItem>()
            .Property(m => m.Price)
            .HasPrecision(10, 2);  // Do 99,999,999.99

        // ===== SCHEDULE =====
        modelBuilder.Entity<DaySchedule>()
            .HasIndex(d => d.DayOfWeek)
            .IsUnique();

        modelBuilder.Entity<TimeSlot>()
            .HasOne(t => t.DaySchedule)
            .WithMany(d => d.TimeSlots)
            .HasForeignKey(t => t.DayScheduleId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<TimeSlot>()
            .HasIndex(t => new { t.DayScheduleId, t.Time })
            .IsUnique();

        modelBuilder.Entity<DateOverride>()
            .HasIndex(d => d.Date)
            .IsUnique();

        // ===== ACTIVITY LOG =====
        modelBuilder.Entity<ActivityLog>()
            .HasOne(a => a.User)
            .WithMany()
            .HasForeignKey(a => a.UserId)
            .OnDelete(DeleteBehavior.SetNull);

        modelBuilder.Entity<ActivityLog>()
            .HasIndex(a => a.Type);

        modelBuilder.Entity<ActivityLog>()
            .HasIndex(a => a.CreatedAt);

        // ===== ORDERS =====
        modelBuilder.Entity<Order>()
            .HasOne(o => o.User)
            .WithMany()
            .HasForeignKey(o => o.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<Order>()
            .HasIndex(o => o.Status);

        modelBuilder.Entity<Order>()
            .HasIndex(o => o.CreatedAt);

        modelBuilder.Entity<Order>()
            .Property(o => o.TotalAmount)
            .HasPrecision(10, 2);

        modelBuilder.Entity<OrderItem>()
            .HasOne(oi => oi.Order)
            .WithMany(o => o.Items)
            .HasForeignKey(oi => oi.OrderId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<OrderItem>()
            .HasOne(oi => oi.MenuItem)
            .WithMany()
            .HasForeignKey(oi => oi.MenuItemId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<OrderItem>()
            .Property(oi => oi.Price)
            .HasPrecision(10, 2);
    }
}
// trigger redeploy
