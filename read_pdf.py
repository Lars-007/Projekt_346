import PyPDF2

def read_pdf(file_path):
    with open(file_path, 'rb') as file:
        reader = PyPDF2.PdfReader(file)
        text = ""
        for page_num in range(len(reader.pages)):
            page = reader.pages[page_num]
            text += f"\\n--- Page {page_num+1} ---\\n"
            text += page.extract_text()
        return text

if __name__ == "__main__":
    pdf_path = r"c:\Coding\dallacque\M346-IMS-Projekt-FaceRecognition-2026.pdf"
    content = read_pdf(pdf_path)
    with open(r"c:\Coding\dallacque\pdf_content.txt", "w", encoding="utf-8") as out:
        out.write(content)
    print("Extracted PDF content to pdf_content.txt")
