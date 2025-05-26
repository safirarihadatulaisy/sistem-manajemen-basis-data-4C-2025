USE stok_penjualan;

-- SOAL 1: TAMPILKAN BERDASARKAN SEMINGGU / 1 BULAN / 3 BULAN
DELIMITER //
CREATE PROCEDURE TampilkanPenjualan3BulanTerakhir()
BEGIN
    SELECT * FROM Penjualan
    WHERE tanggal >= CURDATE() - INTERVAL 7 DAY;
END //
DELIMITER ;

-- Panggilan:
CALL TampilkanPenjualan3BulanTerakhir();

-- SOAL 2: HAPUS TRANSAKSI LEBIH DARI 1 TAHUN JIKA VALID
DELIMITER //
CREATE PROCEDURE HapusTransaksiLamaValid()
BEGIN
    DELETE FROM DetailPenjualan
    WHERE id_penjualan IN (
        SELECT id_penjualan FROM Penjualan
        WHERE tanggal < CURDATE() - INTERVAL 1 YEAR
        AND STATUS = 'selesai'
    );

    DELETE FROM Penjualan
    WHERE tanggal < CURDATE() - INTERVAL 1 YEAR
    AND STATUS = 'selesai';
END //
DELIMITER ;

CALL HapusTransaksiLamaValid();
SELECT * FROM Penjualan;

-- SOAL 3: UBAH STATUS 7 TRANSAKSI PERTAMA
DELIMITER //
CREATE PROCEDURE UbahStatusTransaksi(
    IN p_status_awal VARCHAR(20),
    IN p_status_baru VARCHAR(20)
)
BEGIN
    -- Update maksimal 7 transaksi dengan status awal tertentu, diurutkan dari tanggal terlama
    UPDATE Penjualan
    JOIN (
        SELECT id_penjualan
        FROM Penjualan
        WHERE STATUS = p_status_awal
        ORDER BY tanggal ASC
        LIMIT 7
    ) AS sub
    ON Penjualan.id_penjualan = sub.id_penjualan
    SET Penjualan.status = p_status_baru;
END //
DELIMITER ;

CALL UbahStatusTransaksi('diproses', 'selesai');
SELECT * FROM Penjualan;

-- SOAL 4: TIDAK BISA EDIT USER JIKA PUNYA TRANSAKSI
DELIMITER //
CREATE PROCEDURE EditPelanggan(
    IN p_id INT,
    IN p_nama VARCHAR(100),
    IN p_telp VARCHAR(15)
)
BEGIN
    UPDATE Pelanggan
    SET nama_pelanggan = p_nama,
        no_telp = p_telp
    WHERE id_pelanggan = p_id
    AND id_pelanggan NOT IN (
        SELECT DISTINCT id_pelanggan FROM Penjualan
    );
END //
DELIMITER ;

-- Panggilan:
CALL EditPelanggan(8, 'Lisa Anggraeni', '089998887776');
SELECT * FROM Pelanggan;

-- SOAL 5: BRANCHING STATUS BERDASARKAN JUMLAH
DELIMITER //
CREATE PROCEDURE status_penjualan_terbaru()
BEGIN
    -- Buat temporary table dengan ranking menggunakan ROW_NUMBER()
    DROP TEMPORARY TABLE IF EXISTS temp_penjualan;

    CREATE TEMPORARY TABLE temp_penjualan AS
    SELECT 
        ROW_NUMBER() OVER (ORDER BY total ASC) AS urutan,
        id_penjualan,
        total
    FROM Penjualan
    WHERE tanggal >= CURDATE() - INTERVAL 1 MONTH;

    -- Ambil jumlah data
    SET @jml := (SELECT COUNT(*) FROM temp_penjualan);

    -- Update status berdasarkan urutan
    UPDATE Penjualan
    JOIN temp_penjualan ON Penjualan.id_penjualan = temp_penjualan.id_penjualan
    SET Penjualan.status = 
        IF(temp_penjualan.urutan = 1, 'non-aktif',
            IF(temp_penjualan.urutan = @jml, 'aktif', 'pasif'));
END //
DELIMITER ;

-- Panggilan:
CALL status_penjualan_terbaru();
SELECT * FROM Penjualan ;

-- SOAL 6: LOOPING HITUNG TRANSAKSI BERHASIL 1 BULAN TERAKHIR
DELIMITER //

CREATE PROCEDURE hitung_penjualan_berhasil()
BEGIN
    DECLARE i INT DEFAULT 0;
    DECLARE jml INT;

    SELECT COUNT(*) INTO jml
    FROM Penjualan
    WHERE total > 0 AND tanggal >= CURDATE() - INTERVAL 1 MONTH;

    WHILE i- < jml DO
        SET i = i + 1;
    END WHILE;

    SELECT i AS jumlah_penjualan_berhasil;
END //

DELIMITER ;

CALL hitung_penjualan_berhasil();


DROP PROCEDURE IF EXISTS TampilkanPenjualan3BulanTerakhir;
DROP PROCEDURE IF EXISTS HapusTransaksiLamaValid;
DROP PROCEDURE IF EXISTS UbahStatusTransaksi;
DROP PROCEDURE IF EXISTS status_penjualan_terbaru;
DROP PROCEDURE IF EXISTS hitung_penjualan_berhasil;
