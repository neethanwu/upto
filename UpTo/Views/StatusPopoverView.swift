import SwiftUI

struct StatusPopoverView: View {
    @Bindable var monitor: StatusMonitor
    @State private var showingAddForm = false

    private var contentHeight: CGFloat {
        let serviceRows = CGFloat(max(monitor.services.count, 1)) * 52
        let addForm: CGFloat = showingAddForm ? 80 : 0
        return min(56 + serviceRows + 44 + addForm, 480)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            serviceContent
            Divider()
            footer
        }
        .frame(width: 320, height: contentHeight)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("UpTo")
                    .font(.system(.headline, weight: .semibold))
                statusSubtitle
            }
            Spacer()
            refreshButton
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var statusSubtitle: some View {
        let text = monitor.overallStatus == .operational ? "All Systems Operational" : "Issues Detected"
        return Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    private var refreshButton: some View {
        Button {
            monitor.refresh()
        } label: {
            Image(systemName: "arrow.clockwise")
                .font(.system(size: 12, weight: .medium))
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
    }

    // MARK: - Service Content

    @ViewBuilder
    private var serviceContent: some View {
        if monitor.services.isEmpty {
            emptyState
        } else {
            serviceList
        }
    }

    private var serviceList: some View {
        List {
            ForEach(monitor.services) { service in
                ServiceRowView(service: service)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
            }
            .onDelete { offsets in
                monitor.removeService(at: offsets)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("No services monitored")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Tap + to add a service")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 0) {
            addFormSection
            footerButtons
        }
    }

    @ViewBuilder
    private var addFormSection: some View {
        if showingAddForm {
            AddServiceView(monitor: monitor, isShowing: $showingAddForm)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            Divider()
        }
    }

    private var footerButtons: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showingAddForm.toggle()
                }
            } label: {
                Image(systemName: showingAddForm ? "minus" : "plus")
                    .font(.system(size: 12, weight: .medium))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)

            Spacer()

            Button("Quit UpTo") {
                NSApp.terminate(nil)
            }
            .buttonStyle(.plain)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}
