export const metadata = {
  title: 'Prestige PS',
  description: 'Plastering Quote App',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body style={{ margin: 0, backgroundColor: '#0A1E3F', color: 'white' }}>
        {children}
      </body>
    </html>
  );
}
