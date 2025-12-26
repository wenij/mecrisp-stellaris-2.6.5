import struct
import sys

def add_checksum(filename):
    try:
        with open(filename, 'rb') as f:
            data = bytearray(f.read())
    except FileNotFoundError:
        print(f"找不到檔案: {filename}")
        return

    # 1. 確保檔案夠長
    if len(data) < 32:
        data.extend(b'\x00' * (32 - len(data)))

    # 2. 讀取前 7 個向量 (0x00 - 0x1C)
    vectors = struct.unpack('<7I', data[0:28])
    
    # 3. 計算 Checksum (NXP 規則: 總和的二補數)
    checksum = (0 - sum(vectors)) & 0xFFFFFFFF
    
    print(f"計算出的 Checksum: 0x{checksum:08X}")

    # 4. 填入第 8 個位置 (0x1C)
    checksum_bytes = struct.pack('<I', checksum)
    data[28:32] = checksum_bytes

    # 5. 存成新檔案
    output_filename = filename.replace('.bin', '-checksum.bin')
    with open(output_filename, 'wb') as f:
        f.write(data)
    
    print(f"成功！已建立可燒錄檔案: {output_filename}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("用法: python add_checksum.py <你的檔案.bin>")
    else:
        add_checksum(sys.argv[1])
